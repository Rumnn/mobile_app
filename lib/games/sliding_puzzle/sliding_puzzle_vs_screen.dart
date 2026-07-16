import 'package:flutter/material.dart';

import '../../services/socket_service.dart';
import '../../widgets/nebula_theme.dart';
import 'puzzle_board.dart';
import 'puzzle_controller.dart';

/// VS mode for the Sliding Puzzle.
///
/// Both players receive the same [initialBoard] from the server.
/// A 180-second countdown synced from the server drives the match.
/// Each player's moves are broadcast to the opponent as a live mini-board.
class SlidingPuzzleVsScreen extends StatefulWidget {
  final List<int> initialBoard;
  final int gridSize;
  final List<String> players;
  final String roomCode;
  /// Username of the local player — used to correctly label HUD and determine win/loss.
  final String myUsername;

  const SlidingPuzzleVsScreen({
    super.key,
    required this.initialBoard,
    required this.gridSize,
    required this.players,
    required this.roomCode,
    required this.myUsername,
  });

  @override
  State<SlidingPuzzleVsScreen> createState() => _SlidingPuzzleVsScreenState();
}

class _SlidingPuzzleVsScreenState extends State<SlidingPuzzleVsScreen>
    with SingleTickerProviderStateMixin {
  late PuzzleController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  int _timeLeft = 180;
  bool _gameOver = false;

  // Opponent mini-board state
  List<int> _opponentBoard = [];
  int _opponentMoves = 0;

  // Derived indices: which slot is me, which is the opponent
  late final int _myIndex;
  late final int _opponentIndex;
  late final String _opponentName;

  @override
  void initState() {
    super.initState();

    // Determine which player slot belongs to the local user.
    // The server always sends players as [host, guest].
    _myIndex = widget.players.indexOf(widget.myUsername);
    // If for some reason username is not found, default to slot 0
    final safeMyIndex = _myIndex < 0 ? 0 : _myIndex;
    _opponentIndex = safeMyIndex == 0 ? 1 : 0;
    _opponentName = widget.players.length > _opponentIndex
        ? widget.players[_opponentIndex]
        : 'Đối thủ';

    // Initialize puzzle controller from server-provided board
    _controller = PuzzleController(gridSize: widget.gridSize)
      ..loadBoard(widget.initialBoard)
      ..addListener(_onMyBoardChange);

    // Opponent board initialised to same layout
    _opponentBoard = List<int>.from(widget.initialBoard);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance;

    // Server clock tick
    socket.on('timer_tick', (data) {
      if (!mounted || _gameOver) return;
      setState(() => _timeLeft = (data['timeLeft'] as num).toInt());
    });

    // Opponent moved
    socket.on('opponent_move', (data) {
      if (!mounted || _gameOver) return;
      setState(() {
        _opponentBoard = (data['board'] as List<dynamic>).cast<int>();
        _opponentMoves = (data['movesCount'] as num).toInt();
      });
    });

    // Game ended (win / draw / timeout) — sent by server
    socket.on('game_over', (data) {
      if (!mounted || _gameOver) return; // guard: prevent double dialog
      _gameOver = true;
      _pulseController.stop();
      _showResultDialog(
        reason: data['reason']?.toString() ?? 'win',
        winner: data['winner']?.toString(),
        message: data['message']?.toString() ?? '',
      );
    });

    // Opponent disconnected mid-game (socket closed or explicit leave)
    socket.on('opponent_disconnected', (data) {
      if (!mounted || _gameOver) return; // guard: prevent double dialog
      _gameOver = true;
      _pulseController.stop();
      _showResultDialog(
        reason: 'opponent_left',
        winner: null,
        message: data['message']?.toString() ?? 'Đối thủ đã thoát trận đấu.',
      );
    });
  }

  /// Called every time the local player makes a move.
  void _onMyBoardChange() {
    if (_gameOver) return;
    setState(() {});

    // Sync to server
    SocketService.instance.emit('player_move', {
      'board': _controller.tiles.toList(),
      'movesCount': _controller.moves,
    });

    // Detect win
    if (_controller.won && !_gameOver) {
      _gameOver = true;
      _pulseController.stop();
      SocketService.instance.emit('report_win', {
        'moves': _controller.moves,
        'timeSpent': 180 - _timeLeft,
      });
    }
  }

  @override
  void dispose() {
    // If the widget is disposed before the game ended normally (e.g. user
    // pressed system back button or the OS killed the activity), we must
    // tell the server so the remaining player gets an opponent_disconnected
    // event and the timer / room are cleaned up properly.
    if (!_gameOver) {
      SocketService.instance.emit('leave_room');
    }
    _controller.removeListener(_onMyBoardChange);
    _controller.dispose();
    _pulseController.dispose();
    SocketService.instance.off('timer_tick');
    SocketService.instance.off('opponent_move');
    SocketService.instance.off('game_over');
    SocketService.instance.off('opponent_disconnected');
    super.dispose();
  }

  // ── Result Dialog ──────────────────────────────────────────────────────────

  void _showResultDialog({
    required String reason,
    String? winner,
    required String message,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Result',
        barrierColor: Colors.black.withValues(alpha: 0.7),
        transitionDuration: const Duration(milliseconds: 400),
        transitionBuilder: (ctx, a1, a2, child) => ScaleTransition(
          scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: a1, child: child),
        ),
        pageBuilder: (ctx, _, __) {
          final isDraw = reason == 'timeout';
          // Compare winner username against the local player's own username
          final isWin = reason == 'win' && winner == widget.myUsername;
          final isOpponentLeft = reason == 'opponent_left';

          Color accentColor = isDraw
              ? Colors.orange
              : (isWin || isOpponentLeft ? Colors.greenAccent.shade700 : Colors.redAccent);
          IconData resultIcon = isDraw
              ? Icons.handshake_rounded
              : (isWin || isOpponentLeft ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded);
          String resultText = isDraw
              ? 'HÒA!'
              : (isWin || isOpponentLeft ? 'CHIẾN THẮNG!' : 'THẤT BẠI!');

          return Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1740), Color(0xFF231B5E)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 60,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor.withValues(alpha: 0.15),
                        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 28)],
                      ),
                      child: Icon(resultIcon, color: accentColor, size: 38),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      resultText,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 22),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statCol(Icons.touch_app_rounded, '${_controller.moves}', 'Bước đi', NebulaTheme.primary),
                        Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.1)),
                        _statCol(Icons.timer_rounded, _fmt(180 - _timeLeft), 'Thời gian', NebulaTheme.tertiary),
                        Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.1)),
                        _statCol(Icons.people_rounded, '${widget.players.length}', 'Người chơi', NebulaTheme.secondary),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          SocketService.instance.emit('leave_room');
                          Navigator.of(ctx).pop(); // Close dialog
                          Navigator.of(context).pop(); // Back to lobby
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Về Sảnh Chính', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _statCol(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(label, style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWarning = _timeLeft <= 30;
    final timerColor = _timeLeft <= 10
        ? Colors.redAccent
        : (isWarning ? Colors.orange : NebulaTheme.tertiary);

    return Scaffold(
      backgroundColor: NebulaTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top HUD ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My stats (left side)
                  Expanded(
                    child: _PlayerHud(
                      name: widget.myUsername,
                      moves: _controller.moves,
                      color: NebulaTheme.primary,
                      isMe: true,
                    ),
                  ),

                  // ── Countdown Clock ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Opacity(
                        opacity: isWarning ? _pulseAnim.value : 1.0,
                        child: child,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: timerColor.withValues(alpha: 0.14),
                          border: Border.all(color: timerColor.withValues(alpha: 0.45)),
                          boxShadow: isWarning
                              ? [BoxShadow(color: timerColor.withValues(alpha: 0.25), blurRadius: 16)]
                              : [],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_rounded, color: timerColor, size: 16),
                            const SizedBox(height: 2),
                            Text(
                              _fmt(_timeLeft),
                              style: TextStyle(
                                color: timerColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Opponent stats (right side)
                  Expanded(
                    child: _PlayerHud(
                      name: _opponentName,
                      moves: _opponentMoves,
                      color: NebulaTheme.secondary,
                      isMe: false,
                    ),
                  ),
                ],
              ),
            ),

            // ── Opponent Mini-Board ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: NebulaTheme.secondary.withValues(alpha: 0.07),
                  border: Border.all(color: NebulaTheme.secondary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.remove_red_eye_rounded, color: NebulaTheme.secondary, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          'Bàn cờ đối thủ (thời gian thực)',
                          style: TextStyle(color: NebulaTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: _MiniBoardView(
                        tiles: _opponentBoard,
                        gridSize: widget.gridSize,
                        accentColor: NebulaTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── My Main Board ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        NebulaTheme.surface.withValues(alpha: 0.6),
                        NebulaTheme.background.withValues(alpha: 0.8),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.extension_rounded, color: NebulaTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Bàn cờ của bạn',
                            style: TextStyle(
                              color: NebulaTheme.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_controller.moves} bước',
                            style: TextStyle(color: NebulaTheme.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: PuzzleBoard(controller: _controller),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Player HUD chip ─────────────────────────────────────────────────────────
class _PlayerHud extends StatelessWidget {
  final String name;
  final int moves;
  final Color color;
  final bool isMe;

  const _PlayerHud({
    required this.name,
    required this.moves,
    required this.color,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (isMe)
                Icon(Icons.person_rounded, color: color, size: 14),
              if (!isMe)
                Icon(Icons.person_outline_rounded, color: color, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isMe ? '$name (Bạn)' : name,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$moves bước',
            style: TextStyle(
              color: NebulaTheme.text,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            textAlign: isMe ? TextAlign.left : TextAlign.right,
          ),
        ],
      ),
    );
  }
}

// ── Mini-board (opponent view) ────────────────────────────────────────────────
class _MiniBoardView extends StatelessWidget {
  final List<int> tiles;
  final int gridSize;
  final Color accentColor;

  const _MiniBoardView({
    required this.tiles,
    required this.gridSize,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return Center(
        child: Text(
          'Đang chờ dữ liệu...',
          style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 12),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (_, constraints) {
          const spacing = 3.0;
          final tileSize = (constraints.maxWidth - spacing * (gridSize - 1)) / gridSize;

          return Stack(
            children: List.generate(tiles.length, (i) {
              final value = tiles[i];
              final row = i ~/ gridSize;
              final col = i % gridSize;
              final isEmpty = value == 0;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 120),
                key: ValueKey(value),
                left: col * (tileSize + spacing),
                top: row * (tileSize + spacing),
                width: tileSize,
                height: tileSize,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isEmpty
                        ? Colors.transparent
                        : accentColor.withValues(alpha: 0.22),
                    border: isEmpty
                        ? null
                        : Border.all(color: accentColor.withValues(alpha: 0.35)),
                  ),
                  child: isEmpty
                      ? null
                      : Center(
                          child: Text(
                            '$value',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: tileSize * 0.36,
                            ),
                          ),
                        ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
