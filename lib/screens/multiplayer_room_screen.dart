import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/socket_service.dart';
import '../widgets/nebula_theme.dart';
import '../games/sliding_puzzle/sliding_puzzle_vs_screen.dart';

class MultiplayerRoomScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final bool isHost;

  const MultiplayerRoomScreen({
    super.key,
    required this.initialData,
    required this.isHost,
  });

  @override
  State<MultiplayerRoomScreen> createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends State<MultiplayerRoomScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  late Map<String, dynamic> _roomData;
  bool _isReady = false;
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _roomData = Map<String, dynamic>.from(widget.initialData);
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final socket = SocketService.instance;

    // Room state updated (player joined / ready changed)
    socket.on('room_updated', (data) {
      if (!mounted) return;
      setState(() => _roomData = Map<String, dynamic>.from(data as Map));
    });

    // Chat message received
    socket.on('message_received', (data) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'username': data['username'].toString(),
          'text': data['text'].toString(),
          'time': data['timestamp'].toString(),
        });
      });
      _scrollToBottom();
    });

    // Game starting!
    socket.on('game_start', (data) {
      if (!mounted) return;
      final board = (data['board'] as List<dynamic>?)?.cast<int>() ??
          (data['initialBoard'] as List<dynamic>).cast<int>();
      final players = (data['players'] as List<dynamic>).cast<String>();
      final gridSize = (_roomData['gridSize'] as int?) ?? 3;

      // Determine our own username:
      // Server always orders players as [host, guest].
      // widget.isHost==true  => we are players[0]
      // widget.isHost==false => we are players[1]
      final myUsername = widget.isHost
          ? (players.isNotEmpty ? players[0] : '')
          : (players.length > 1 ? players[1] : '');

      // Clean up room listeners before navigating
      socket.off('room_updated');
      socket.off('message_received');
      socket.off('game_start');
      socket.off('opponent_disconnected');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SlidingPuzzleVsScreen(
            initialBoard: board,
            gridSize: gridSize,
            players: players,
            roomCode: _roomData['code'].toString(),
            myUsername: myUsername,
          ),
        ),
      );
    });

    // Opponent disconnected while waiting
    socket.on('opponent_disconnected', (data) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'username': 'Hệ thống',
          'text': '⚠️ ${data['message'] ?? 'Đối thủ đã thoát phòng.'}',
          'time': '',
        });
        // Reset room state
        _isReady = false;
        final players = (_roomData['players'] as List?)
            ?.where((p) => p['username'] != null)
            .map((p) => Map<String, dynamic>.from(p as Map))
            .toList();
        if (players != null) _roomData['players'] = players;
      });
    });
  }

  @override
  void dispose() {
    SocketService.instance.off('room_updated');
    SocketService.instance.off('message_received');
    SocketService.instance.off('game_start');
    SocketService.instance.off('opponent_disconnected');
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleReady() {
    setState(() => _isReady = !_isReady);
    SocketService.instance.emit('toggle_ready', _isReady);
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    SocketService.instance.emit('send_message', text);
    _msgController.clear();
  }

  void _leaveRoom() {
    SocketService.instance.emit('leave_room');
    SocketService.instance.off('room_updated');
    SocketService.instance.off('message_received');
    SocketService.instance.off('game_start');
    SocketService.instance.off('opponent_disconnected');
    if (mounted) Navigator.pop(context);
  }

  String get _roomCode => _roomData['code']?.toString() ?? '----';
  List<dynamic> get _players => (_roomData['players'] as List<dynamic>?) ?? [];
  bool get _canStart => _players.length == 2;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveRoom();
      },
      child: Scaffold(
        backgroundColor: NebulaTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: NebulaTheme.textSubtle),
            onPressed: _leaveRoom,
          ),
          title: Row(
            children: [
              ShaderMask(
                shaderCallback: (b) =>
                    LinearGradient(colors: [NebulaTheme.primary, NebulaTheme.secondary])
                        .createShader(b),
                child: const Text(
                  'Phòng chờ',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 20),
                ),
              ),
            ],
          ),
          actions: [
            // Room code copy chip
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _roomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã sao chép mã phòng: $_roomCode'),
                    backgroundColor: NebulaTheme.surfaceHigh,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: NebulaTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: NebulaTheme.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, color: NebulaTheme.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _roomCode,
                      style: TextStyle(
                        color: NebulaTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Players Section ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _PlayerSlot(player: _players.isNotEmpty ? _players[0] : null, isMe: widget.isHost),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(Icons.close_rounded, color: NebulaTheme.secondary, size: 28),
                        Text('VS', style: TextStyle(
                          color: NebulaTheme.secondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        )),
                      ],
                    ),
                  ),
                  _PlayerSlot(player: _players.length > 1 ? _players[1] : null, isMe: !widget.isHost),
                ],
              ),
            ),

            // ── Waiting hint ─────────────────────────────────────────────────
            if (!_canStart)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: NebulaTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NebulaTheme.secondary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Đang chờ đối thủ tham gia phòng...',
                        style: TextStyle(color: NebulaTheme.secondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // ── Chat ─────────────────────────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: NebulaTheme.glass(),
                child: Column(
                  children: [
                    // Chat header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.forum_rounded, color: NebulaTheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Chat phòng chờ',
                            style: TextStyle(
                              color: NebulaTheme.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                    // Messages
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Text(
                                'Hãy gửi tin nhắn để chào đối thủ!',
                                style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 13),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) => _ChatBubble(message: _messages[i]),
                            ),
                    ),
                    // Input
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgController,
                              style: TextStyle(color: NebulaTheme.text, fontSize: 14),
                              onSubmitted: (_) => _sendMessage(),
                              decoration: InputDecoration(
                                hintText: 'Nhập tin nhắn...',
                                hintStyle: TextStyle(color: NebulaTheme.textSubtle, fontSize: 14),
                                filled: true,
                                fillColor: NebulaTheme.surfaceHigh.withValues(alpha: 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: NebulaTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Ready Button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton.icon(
                    onPressed: _canStart ? _toggleReady : null,
                    icon: Icon(
                      _isReady ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 22,
                    ),
                    label: Text(
                      _isReady ? 'Đã sẵn sàng! Chờ đối thủ...' : 'Sẵn sàng chiến đấu',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isReady ? Colors.green.shade700 : NebulaTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: NebulaTheme.surfaceHigh,
                      disabledForegroundColor: NebulaTheme.textSubtle,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
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

// ── Player slot widget ────────────────────────────────────────────────────────
class _PlayerSlot extends StatelessWidget {
  final dynamic player;
  final bool isMe;

  const _PlayerSlot({this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final name = player?['username']?.toString() ?? '???';
    final ready = player?['ready'] == true;
    final isEmpty = player == null;

    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isEmpty
            ? NebulaTheme.surfaceHigh.withValues(alpha: 0.3)
            : NebulaTheme.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: isEmpty
              ? Colors.white.withValues(alpha: 0.08)
              : (ready ? Colors.green.shade500 : NebulaTheme.primary).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: NebulaTheme.primary.withValues(alpha: 0.15),
                backgroundImage: isEmpty
                    ? null
                    : NetworkImage('https://i.pravatar.cc/100?u=$name'),
                child: isEmpty
                    ? Icon(Icons.person_add_outlined, color: NebulaTheme.textSubtle, size: 28)
                    : null,
              ),
              if (!isEmpty)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: ready ? Colors.green.shade500 : Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: NebulaTheme.background, width: 2),
                  ),
                  child: Icon(
                    ready ? Icons.check : Icons.hourglass_empty_rounded,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isEmpty ? 'Chờ...' : name,
            style: TextStyle(
              color: isEmpty ? NebulaTheme.textSubtle : NebulaTheme.text,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (isMe && !isEmpty)
            Text('(Bạn)',
                style: TextStyle(color: NebulaTheme.primary, fontSize: 11)),
          const SizedBox(height: 4),
          if (!isEmpty)
            Text(
              ready ? '✅ Sẵn sàng' : '⏳ Chờ...',
              style: TextStyle(
                color: ready ? Colors.green.shade400 : Colors.orange,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final Map<String, String> message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSystem = message['username'] == 'Hệ thống';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: isSystem
          ? Center(
              child: Text(
                message['text'] ?? '',
                style: TextStyle(
                  color: NebulaTheme.textSubtle,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: NebulaTheme.primary.withValues(alpha: 0.15),
                  backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/60?u=${message['username']}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(message['username'] ?? '',
                              style: TextStyle(
                                  color: NebulaTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Text(message['time'] ?? '',
                              style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(message['text'] ?? '',
                          style: TextStyle(color: NebulaTheme.text, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
