const jwt = require("jsonwebtoken");
const User = require("../models/User");
const Message = require("../models/Message");
const Follow = require("../models/Follow");

// In-memory room storage
// Key: roomCode (4 uppercase characters)
// Value: { code, gameType, gridSize, players: [{ socketId, userId, username, ready, board: [] }], state: 'waiting'|'playing', timeLeft: 180, timer: null }
const rooms = {};

// Matchmaking queue: players waiting to be matched.
// Each entry: { socketId, userId, username, gridSize }
const matchmakingQueue = [];

// Helper: Generate a unique room code
function generateRoomCode() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  let code = "";
  do {
    code = "";
    for (let i = 0; i < 4; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
  } while (rooms[code]); // Ensure uniqueness
  return code;
}

// Helper: Check if sliding puzzle board is solvable
function isSolvable(tiles, gridSize) {
  const n = gridSize * gridSize;
  let inversions = 0;
  for (let i = 0; i < n; i++) {
    if (tiles[i] === 0) continue;
    for (let j = i + 1; j < n; j++) {
      if (tiles[j] === 0) continue;
      if (tiles[i] > tiles[j]) inversions++;
    }
  }

  if (gridSize % 2 !== 0) {
    return inversions % 2 === 0;
  } else {
    const blankIndex = tiles.indexOf(0);
    const blankRowFromBottom = gridSize - Math.floor(blankIndex / gridSize);
    return (inversions + blankRowFromBottom) % 2 === 0;
  }
}

// Helper: Check if sliding puzzle board is already solved
function isSolved(tiles) {
  const n = tiles.length;
  for (let i = 0; i < n; i++) {
    if (tiles[i] !== (i + 1) % n) return false;
  }
  return true;
}

// Helper: Generate solvable sliding puzzle starting board
function generateSolvableBoard(gridSize) {
  const n = gridSize * gridSize;
  let tiles = Array.from({ length: n }, (_, i) => (i + 1) % n); // [1, 2, ..., n-1, 0]

  let attempts = 0;
  do {
    // Fisher-Yates Shuffle
    for (let i = n - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = tiles[i];
      tiles[i] = tiles[j];
      tiles[j] = temp;
    }
    attempts++;
  } while ((!isSolvable(tiles, gridSize) || isSolved(tiles)) && attempts < 1000);

  return tiles;
}

function initSocketIO(io) {
  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.query?.token;
      if (!token) {
        return next(new Error("Authentication error: Token missing"));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.id).select("-password");
      if (!user) {
        return next(new Error("Authentication error: User not found"));
      }

      socket.user = user;
      next();
    } catch (err) {
      console.error("Socket authentication error:", err.message);
      return next(new Error("Authentication error: Invalid token"));
    }
  });

  io.on("connection", (socket) => {
    console.log(`User connected: ${socket.user.username} (Socket: ${socket.id})`);
    
    // Join personal user room to receive direct messages
    socket.join(socket.user._id.toString());

    let currentRoomCode = null;

    // Helper: Leave room handler
    const handleLeaveRoom = () => {
      if (!currentRoomCode || !rooms[currentRoomCode]) return;

      const room = rooms[currentRoomCode];
      const leavingRoomCode = currentRoomCode; // snapshot before clearing

      // Remove player
      room.players = room.players.filter(p => p.socketId !== socket.id);
      socket.leave(leavingRoomCode);
      currentRoomCode = null; // clear immediately so re-entrant calls are safe

      console.log(`${socket.user.username} left room ${leavingRoomCode}`);

      if (room.players.length === 0) {
        // Destroy room — stop timer and delete from memory
        if (room.timer) { clearInterval(room.timer); room.timer = null; }
        delete rooms[leavingRoomCode];
        console.log(`Room ${leavingRoomCode} destroyed (empty)`);
      } else if (room.state === "playing") {
        // Match was active: stop timer and declare remaining player the winner.
        // Do NOT send room_updated here — remaining player is in the VS screen
        // and only listens for opponent_disconnected / game_over.
        if (room.timer) { clearInterval(room.timer); room.timer = null; }
        room.state = "waiting";
        room.players.forEach(p => p.ready = false);

        io.to(leavingRoomCode).emit("opponent_disconnected", {
          message: "Đối thủ đã thoát trận đấu. Bạn thắng cuộc!",
          winner: room.players[0].username,
        });
      } else {
        // Waiting state: just refresh the room card for remaining player
        io.to(leavingRoomCode).emit("room_updated", {
          code: room.code,
          gameType: room.gameType,
          gridSize: room.gridSize,
          players: room.players.map(p => ({
            username: p.username,
            ready: p.ready
          })),
          state: room.state
        });
      }
    };

    // 1. Create Room
    socket.on("create_room", (data) => {
      try {
        if (currentRoomCode) {
          handleLeaveRoom();
        }

        const gameType = data.gameType || "Sliding Puzzle";
        const gridSize = data.gridSize || 3;
        const code = generateRoomCode();

        rooms[code] = {
          code,
          gameType,
          gridSize,
          players: [{
            socketId: socket.id,
            userId: socket.user._id.toString(),
            username: socket.user.username,
            ready: false,
            board: []
          }],
          state: "waiting",
          timeLeft: 180,
          timer: null
        };

        currentRoomCode = code;
        socket.join(code);

        console.log(`Room ${code} created by ${socket.user.username}`);

        socket.emit("room_created", {
          code,
          gameType,
          gridSize,
          players: [{ username: socket.user.username, ready: false }],
          state: "waiting"
        });
      } catch (err) {
        socket.emit("error_message", "Không thể tạo phòng. Vui lòng thử lại.");
      }
    });

    // 2. Join Room
    socket.on("join_room", (data) => {
      try {
        const { roomCode } = data;
        if (!roomCode) {
          return socket.emit("error_message", "Mã phòng không hợp lệ.");
        }

        const code = roomCode.trim().toUpperCase();
        const room = rooms[code];

        if (!room) {
          return socket.emit("error_message", "Phòng không tồn tại.");
        }

        if (room.players.length >= 2) {
          return socket.emit("error_message", "Phòng đã đầy (tối đa 2 người).");
        }

        if (room.state === "playing") {
          return socket.emit("error_message", "Trận đấu trong phòng này đã bắt đầu.");
        }

        // Prevent a user from joining their own room (same account, different tab/device)
        if (room.players.some(p => p.userId === socket.user._id.toString())) {
          return socket.emit("error_message", "Bạn đã có mặt trong phòng này rồi.");
        }

        if (currentRoomCode) {
          handleLeaveRoom();
        }

        room.players.push({
          socketId: socket.id,
          userId: socket.user._id.toString(),
          username: socket.user.username,
          ready: false,
          board: []
        });

        currentRoomCode = code;
        socket.join(code);

        console.log(`${socket.user.username} joined room ${code}`);

        // Notify room members
        io.to(code).emit("room_updated", {
          code: room.code,
          gameType: room.gameType,
          gridSize: room.gridSize,
          players: room.players.map(p => ({
            username: p.username,
            ready: p.ready
          })),
          state: room.state
        });
      } catch (err) {
        socket.emit("error_message", "Không thể tham gia phòng.");
      }
    });

    // 3. Toggle Ready
    socket.on("toggle_ready", (readyStatus) => {
      if (!currentRoomCode || !rooms[currentRoomCode]) {
        return socket.emit("error_message", "Bạn chưa tham gia phòng nào.");
      }

      const room = rooms[currentRoomCode];
      if (room.state === "playing") return;

      const player = room.players.find(p => p.socketId === socket.id);
      if (player) {
        player.ready = readyStatus;
      }

      // Notify all players in room
      io.to(currentRoomCode).emit("room_updated", {
        code: room.code,
        gameType: room.gameType,
        gridSize: room.gridSize,
        players: room.players.map(p => ({
          username: p.username,
          ready: p.ready
        })),
        state: room.state
      });

      // Check if both players are ready to start the game
      if (room.players.length === 2 && room.players.every(p => p.ready)) {
        room.state = "playing";
        room.timeLeft = 180;
        
        // Generate the identical solvable board for both players
        const initialBoard = generateSolvableBoard(room.gridSize);
        
        // Reset player boards
        room.players.forEach(p => {
          p.board = [...initialBoard];
        });

        // Notify game start
        io.to(currentRoomCode).emit("game_start", {
          initialBoard,
          players: room.players.map(p => p.username),
          timeLeft: room.timeLeft
        });

        // Start countdown timer on server.
        // IMPORTANT: Capture the room code as a const so the closure is not
        // affected if currentRoomCode is reassigned later (e.g. player rejoins
        // a different room via a new socket event).
        if (room.timer) { clearInterval(room.timer); room.timer = null; }
        const timerRoomCode = currentRoomCode;
        room.timer = setInterval(() => {
          // Guard: room may have been deleted while timer was pending
          if (!rooms[timerRoomCode]) {
            clearInterval(room.timer);
            room.timer = null;
            return;
          }

          room.timeLeft--;
          io.to(timerRoomCode).emit("timer_tick", { timeLeft: room.timeLeft });

          if (room.timeLeft <= 0) {
            // Timeout -> DRAW
            clearInterval(room.timer);
            room.timer = null;
            room.state = "waiting";
            room.players.forEach(p => p.ready = false);

            io.to(timerRoomCode).emit("game_over", {
              reason: "timeout",
              winner: null,
              message: "Hết thời gian 3 phút! Cả hai đều không giải được. Trận đấu Hòa."
            });
          }
        }, 1000);
      }
    });

    // 4. Send Room Message (Chat)
    socket.on("send_message", (messageText) => {
      if (!currentRoomCode) return;
      io.to(currentRoomCode).emit("message_received", {
        username: socket.user.username,
        text: messageText,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })
      });
    });

    // 5. Sync player movement
    socket.on("player_move", (data) => {
      // data: { board: [tiles], movesCount: number }
      if (!currentRoomCode || !rooms[currentRoomCode]) return;
      const room = rooms[currentRoomCode];
      if (room.state !== "playing") return;

      const player = room.players.find(p => p.socketId === socket.id);
      if (player) {
        player.board = data.board;
      }

      // Broadcast move to the opponent
      socket.to(currentRoomCode).emit("opponent_move", {
        username: socket.user.username,
        board: data.board,
        movesCount: data.movesCount
      });
    });

    // 6. Report Win
    socket.on("report_win", (data) => {
      // data: { moves: number, timeSpent: number }
      if (!currentRoomCode || !rooms[currentRoomCode]) return;
      const room = rooms[currentRoomCode];
      if (room.state !== "playing") return;

      // Stop timer
      if (room.timer) {
        clearInterval(room.timer);
        room.timer = null;
      }

      room.state = "waiting";
      room.players.forEach(p => p.ready = false);

      console.log(`Game in room ${currentRoomCode} won by ${socket.user.username}`);

      io.to(currentRoomCode).emit("game_over", {
        reason: "win",
        winner: socket.user.username,
        message: `Trận đấu kết thúc! ${socket.user.username} đã giải xong câu đố trong ${data.moves} bước đi (${data.timeSpent} giây)!`
      });
    });

    // 8. Matchmaking: join queue
    socket.on("join_queue", (data) => {
      try {
        const gridSize = parseInt(data?.gridSize) || 3;

        // Leave any active room first
        if (currentRoomCode) handleLeaveRoom();

        // Remove any previous queue entry for this user (reconnect / double-tap)
        const existingIdx = matchmakingQueue.findIndex(p => p.userId === socket.user._id.toString());
        if (existingIdx !== -1) matchmakingQueue.splice(existingIdx, 1);

        // Look for a compatible opponent (same gridSize, different user)
        const opponentIdx = matchmakingQueue.findIndex(
          p => p.gridSize === gridSize && p.userId !== socket.user._id.toString()
        );

        if (opponentIdx !== -1) {
          // ── Match found! ──────────────────────────────────────────────────
          const opponent = matchmakingQueue.splice(opponentIdx, 1)[0];
          const code = generateRoomCode();
          const board = generateSolvableBoard(gridSize);

          // Create room with both players already "playing"
          rooms[code] = {
            code,
            gameType: "Sliding Puzzle",
            gridSize,
            players: [
              // opponent is player[0] (they were waiting first)
              { socketId: opponent.socketId, userId: opponent.userId, username: opponent.username, ready: true, board: [...board] },
              // current socket is player[1]
              { socketId: socket.id, userId: socket.user._id.toString(), username: socket.user.username, ready: true, board: [...board] }
            ],
            state: "playing",
            timeLeft: 180,
            timer: null
          };

          console.log(`Matchmaking: ${opponent.username} vs ${socket.user.username} → room ${code}`);

          // Notify each player individually so they each know their own username
          io.to(opponent.socketId).emit("match_found", {
            roomCode: code,
            board,
            players: [opponent.username, socket.user.username],
            gridSize,
            myUsername: opponent.username
          });
          socket.emit("match_found", {
            roomCode: code,
            board,
            players: [opponent.username, socket.user.username],
            gridSize,
            myUsername: socket.user.username
          });

          // Start timer after a 3-second grace period so both clients have
          // time to navigate to the VS screen and register their listeners.
          setTimeout(() => {
            const room = rooms[code];
            if (!room || room.state !== "playing") return;

            room.timer = setInterval(() => {
              const r = rooms[code];
              if (!r) { clearInterval(room.timer); room.timer = null; return; }

              r.timeLeft--;
              io.to(code).emit("timer_tick", { timeLeft: r.timeLeft });

              if (r.timeLeft <= 0) {
                clearInterval(r.timer);
                r.timer = null;
                r.state = "waiting";
                r.players.forEach(p => p.ready = false);
                io.to(code).emit("game_over", {
                  reason: "timeout",
                  winner: null,
                  message: "Hết thời gian 3 phút! Cả hai đều không giải được. Trận đấu Hòa."
                });
              }
            }, 1000);
          }, 3000);

        } else {
          // ── Add to queue, wait for opponent ───────────────────────────────
          matchmakingQueue.push({
            socketId: socket.id,
            userId: socket.user._id.toString(),
            username: socket.user.username,
            gridSize
          });
          socket.emit("queue_update", {
            searching: true,
            queueLength: matchmakingQueue.length
          });
          console.log(`${socket.user.username} joined matchmaking queue [gridSize=${gridSize}, queue=${matchmakingQueue.length}]`);
        }
      } catch (err) {
        console.error("join_queue error:", err);
        socket.emit("error_message", "Lỗi kết nối matchmaking. Vui lòng thử lại.");
      }
    });

    // 9. Matchmaking: leave queue
    socket.on("leave_queue", () => {
      const idx = matchmakingQueue.findIndex(p => p.socketId === socket.id);
      if (idx !== -1) {
        matchmakingQueue.splice(idx, 1);
        console.log(`${socket.user.username} left matchmaking queue (${matchmakingQueue.length} remaining)`);
      }
      socket.emit("queue_left", { cancelled: true });
    });

    // 10. Confirm match join — client calls this after receiving match_found.
    //     Sets currentRoomCode and adds socket to the socket.io room so that
    //     timer_tick / game_over / opponent_move events are received correctly.
    socket.on("confirm_match_join", (data) => {
      const roomCode = data?.roomCode;
      if (!roomCode || !rooms[roomCode]) return;

      // Avoid double-joining
      if (currentRoomCode === roomCode) return;

      currentRoomCode = roomCode;
      socket.join(roomCode);
      console.log(`${socket.user.username} confirmed join in matched room ${roomCode}`);
    });

    // 7. Leave Room manually
    socket.on("leave_room", () => {
      handleLeaveRoom();
    });

    // 11. Send direct message
    socket.on("send_direct_message", async (data) => {
      try {
        const { receiverId, content } = data;
        if (!receiverId || !content || !content.trim()) return;

        // Verify mutual follow (friendship)
        const followsReceiver = await Follow.findOne({ follower: socket.user._id, following: receiverId });
        const followsSender = await Follow.findOne({ follower: receiverId, following: socket.user._id });

        if (!followsReceiver || !followsSender) {
          return socket.emit("error_message", "Hai người cần phải kết bạn (theo dõi nhau) mới có thể nhắn tin.");
        }

        const newMessage = await Message.create({
          sender: socket.user._id,
          receiver: receiverId,
          content: content.trim(),
          read: false
        });

        const populatedMessage = await Message.findById(newMessage._id)
          .populate("sender", "username avatarURL")
          .populate("receiver", "username avatarURL");

        // Emit to receiver's room
        io.to(receiverId).emit("new_direct_message", populatedMessage);
        // Emit back to sender (so other tabs/devices of the same user sync)
        socket.emit("new_direct_message", populatedMessage);
      } catch (err) {
        console.error("send_direct_message error:", err);
      }
    });

    // 12. Direct message typing indicator
    socket.on("typing", (data) => {
      // data: { receiverId, isTyping }
      const { receiverId, isTyping } = data;
      if (!receiverId) return;

      io.to(receiverId).emit("typing_status", {
        senderId: socket.user._id.toString(),
        isTyping: !!isTyping
      });
    });

    // 8. Disconnect
    socket.on("disconnect", () => {
      console.log(`User disconnected: ${socket.user.username} (Socket: ${socket.id})`);
      // Also remove from matchmaking queue if they were still waiting
      const qIdx = matchmakingQueue.findIndex(p => p.socketId === socket.id);
      if (qIdx !== -1) matchmakingQueue.splice(qIdx, 1);
      handleLeaveRoom();
    });
  });
}

module.exports = { initSocketIO };
