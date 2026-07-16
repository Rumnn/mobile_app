import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/socket_service.dart';
import '../widgets/nebula_theme.dart';
import 'matchmaking_screen.dart';
import 'multiplayer_room_screen.dart';

class MultiplayerLobbyScreen extends StatefulWidget {
  const MultiplayerLobbyScreen({super.key});

  @override
  State<MultiplayerLobbyScreen> createState() => _MultiplayerLobbyScreenState();
}

class _MultiplayerLobbyScreenState extends State<MultiplayerLobbyScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  bool _isConnecting = false;
  String? _errorMessage;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Selected game settings
  int _gridSize = 3;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Clean up any pending socket listeners so they don't fire on a
    // deallocated widget if the server responds after the user has
    // already navigated away from this screen.
    SocketService.instance.off('room_created');
    SocketService.instance.off('room_updated');
    SocketService.instance.off('error_message');
    _pulseController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _connectAndDo(Future<void> Function() action) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      await SocketService.instance.connect();
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Không thể kết nối server. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  void _createRoom() {
    _connectAndDo(() async {
      final socket = SocketService.instance;

      // Listen for room_created once
      socket.off('room_created');
      socket.off('error_message');

      socket.on('error_message', (msg) {
        if (mounted) setState(() => _errorMessage = msg.toString());
      });

      socket.on('room_created', (data) {
        socket.off('room_created');
        socket.off('error_message');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiplayerRoomScreen(
                initialData: Map<String, dynamic>.from(data as Map),
                isHost: true,
              ),
            ),
          );
        }
      });

      socket.emit('create_room', {'gameType': 'Sliding Puzzle', 'gridSize': _gridSize});
    });
  }

  void _joinRoom() {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 4) {
      setState(() => _errorMessage = 'Mã phòng phải gồm đúng 4 ký tự.');
      return;
    }

    _connectAndDo(() async {
      final socket = SocketService.instance;

      socket.off('room_updated');
      socket.off('error_message');

      socket.on('error_message', (msg) {
        socket.off('error_message');
        if (mounted) setState(() => _errorMessage = msg.toString());
      });

      socket.on('room_updated', (data) {
        socket.off('room_updated');
        socket.off('error_message');
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiplayerRoomScreen(
                initialData: Map<String, dynamic>.from(data as Map),
                isHost: false,
              ),
            ),
          );
        }
      });

      socket.emit('join_room', {'roomCode': code});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebulaTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: NebulaTheme.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              LinearGradient(colors: [NebulaTheme.primary, NebulaTheme.secondary])
                  .createShader(bounds),
          child: const Text(
            'Chế độ Đối Kháng',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // ── Hero Banner ──────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, child) => Transform.scale(
                scale: _pulseAnim.value,
                child: child,
              ),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NebulaTheme.primary.withValues(alpha: 0.4),
                      NebulaTheme.secondary.withValues(alpha: 0.25),
                      NebulaTheme.tertiary.withValues(alpha: 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: NebulaTheme.primary.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NebulaTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background grid dots decoration
                    Positioned.fill(
                      child: CustomPaint(painter: _GridDotsPainter()),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_esports_rounded,
                            color: NebulaTheme.primary, size: 52),
                        const SizedBox(height: 10),
                        Text(
                          'Sliding Puzzle VS',
                          style: TextStyle(
                            color: NebulaTheme.text,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thi đấu thời gian thực • Giới hạn 3 phút',
                          style: TextStyle(
                            color: NebulaTheme.textSubtle,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Quick Match Hero Card ─────────────────────────────────────────
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchmakingScreen(gridSize: _gridSize),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NebulaTheme.primary.withValues(alpha: 0.5),
                      NebulaTheme.secondary.withValues(alpha: 0.35),
                    ],
                  ),
                  border: Border.all(
                    color: NebulaTheme.primary.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NebulaTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 28,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: const Center(
                        child: Icon(Icons.radar_rounded, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tìm đối thủ nhanh',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Hệ thống tự động ghép đôi bạn với đối thủ tương đương',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'QUICK MATCH',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Divider ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'HOẶC TẠO / VÀO PHÒNG',
                    style: TextStyle(
                      color: NebulaTheme.textSubtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
              ],
            ),
            const SizedBox(height: 16),

            // ── Grid Size Selector ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: NebulaTheme.glass(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kích thước bàn cờ',
                    style: TextStyle(
                      color: NebulaTheme.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _sizeTab(3, 'Dễ · 3×3'),
                      const SizedBox(width: 10),
                      _sizeTab(4, 'Khó · 4×4'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Create Room ─────────────────────────────────────────────────
            _ActionCard(
              icon: Icons.add_circle_outline_rounded,
              color: NebulaTheme.primary,
              title: 'Tạo phòng mới',
              subtitle: 'Nhận mã phòng để chia sẻ với bạn bè',
              buttonLabel: 'Tạo phòng',
              isLoading: _isConnecting,
              onTap: _isConnecting ? null : _createRoom,
            ),
            const SizedBox(height: 14),

            // ── Join Room ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: NebulaTheme.glass(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NebulaTheme.secondary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.login_rounded, color: NebulaTheme.secondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vào phòng bằng mã',
                              style: TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700, fontSize: 15)),
                          Text('Nhập mã 4 ký tự từ bạn bè',
                              style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Code Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                            LengthLimitingTextInputFormatter(4),
                          ],
                          style: TextStyle(
                            color: NebulaTheme.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                            letterSpacing: 8,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ABCD',
                            hintStyle: TextStyle(
                              color: NebulaTheme.textSubtle.withValues(alpha: 0.4),
                              letterSpacing: 8,
                              fontSize: 22,
                            ),
                            filled: true,
                            fillColor: NebulaTheme.surfaceHigh.withValues(alpha: 0.6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isConnecting ? null : _joinRoom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NebulaTheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: _isConnecting
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Vào', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Error Message ────────────────────────────────────────────────
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            // ── Rules Card ────────────────────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: NebulaTheme.glass(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📋 Luật chơi',
                      style: TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 10),
                  _rule(Icons.timer, 'Giới hạn 3 phút mỗi trận. Hết giờ → Hòa.'),
                  _rule(Icons.grid_on_rounded, 'Cả hai nhận cùng một cấu hình bàn cờ.'),
                  _rule(Icons.visibility, 'Xem bàn cờ thu nhỏ của đối thủ theo thời gian thực.'),
                  _rule(Icons.emoji_events_rounded, 'Ai giải xong trước → Thắng ngay lập tức.'),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sizeTab(int size, String label) {
    final active = _gridSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gridSize = size),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: active
                ? LinearGradient(colors: [
                    NebulaTheme.primary.withValues(alpha: 0.35),
                    NebulaTheme.primary.withValues(alpha: 0.15),
                  ])
                : null,
            color: active ? null : NebulaTheme.surfaceHigh.withValues(alpha: 0.3),
            border: active
                ? Border.all(color: NebulaTheme.primary.withValues(alpha: 0.4))
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? NebulaTheme.primary : NebulaTheme.textSubtle,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _rule(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: NebulaTheme.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Action card (Create Room) ─────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NebulaTheme.glass(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(color: NebulaTheme.text, fontWeight: FontWeight.w700, fontSize: 15)),
                Text(subtitle,
                    style: TextStyle(color: NebulaTheme.textSubtle, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Background grid dots decoration ──────────────────────────────────────────
class _GridDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    const radius = 1.5;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
