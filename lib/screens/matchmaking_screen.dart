import 'dart:async';
import 'package:flutter/material.dart';

import '../services/socket_service.dart';
import '../widgets/nebula_theme.dart';
import '../games/sliding_puzzle/sliding_puzzle_vs_screen.dart';

/// Matchmaking screen — displayed while the system is searching for an opponent.
///
/// Flow:
/// 1. Emits [join_queue] with the selected [gridSize].
/// 2. If matched → server sends [match_found] → navigate to [SlidingPuzzleVsScreen].
/// 3. If user cancels → emit [leave_queue] → pop.
class MatchmakingScreen extends StatefulWidget {
  final int gridSize;

  const MatchmakingScreen({super.key, required this.gridSize});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with TickerProviderStateMixin {
  // Radar ripple animations (staggered by 600ms each)
  late final AnimationController _wave1;
  late final AnimationController _wave2;
  late final AnimationController _wave3;
  // Center icon pulse
  late final AnimationController _pulse;

  int _elapsed = 0;
  Timer? _clockTimer;

  bool _matchFound = false;
  bool _cancelling = false;

  // Opponent name revealed when match found
  String _opponentName = '';

  @override
  void initState() {
    super.initState();

    const waveDuration = Duration(milliseconds: 2000);
    _wave1 = AnimationController(vsync: this, duration: waveDuration)..repeat();
    _wave2 = AnimationController(vsync: this, duration: waveDuration)
      ..forward(from: 1 / 3)
      ..repeat();
    _wave3 = AnimationController(vsync: this, duration: waveDuration)
      ..forward(from: 2 / 3)
      ..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed++);
    });

    // Connect and join the matchmaking queue
    _joinQueue();

    SocketService.instance.on('match_found', _onMatchFound);
    SocketService.instance.on('queue_left', _onQueueLeft);
  }

  Future<void> _joinQueue() async {
    try {
      await SocketService.instance.connect();
      SocketService.instance.emit('join_queue', {'gridSize': widget.gridSize});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể kết nối server. Vui lòng thử lại.'),
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  // ── Socket handlers ──────────────────────────────────────────────────────────

  void _onMatchFound(dynamic data) {
    if (!mounted || _matchFound) return;
    setState(() {
      _matchFound = true;
      _opponentName = data['players'] is List
          ? (data['players'] as List).cast<String>().firstWhere(
              (p) => p != (data['myUsername']?.toString() ?? ''),
              orElse: () => 'Đối thủ',
            )
          : 'Đối thủ';
    });

    final board = (data['board'] as List<dynamic>).cast<int>();
    final players = (data['players'] as List<dynamic>).cast<String>();
    final gridSize = (data['gridSize'] as num).toInt();
    final myUsername = data['myUsername']?.toString() ?? '';
    final roomCode = data['roomCode']?.toString() ?? '';

    // Tell server we acknowledge and have joined the socket.io room
    SocketService.instance.emit('confirm_match_join', {'roomCode': roomCode});

    _stopAll();

    // Brief visual delay so the user sees "Tìm thấy!" flash before navigating
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _cleanupListeners();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SlidingPuzzleVsScreen(
            initialBoard: board,
            gridSize: gridSize,
            players: players,
            roomCode: roomCode,
            myUsername: myUsername,
          ),
        ),
      );
    });
  }

  void _onQueueLeft(dynamic _) {
    if (mounted && !_matchFound) Navigator.pop(context);
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _cancel() async {
    if (_cancelling || _matchFound) return;
    setState(() => _cancelling = true);
    _stopAll();
    SocketService.instance.emit('leave_queue');
    // queue_left event will pop; fallback pop after 500ms
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _cleanupListeners();
      Navigator.pop(context);
    }
  }

  void _stopAll() {
    _clockTimer?.cancel();
    _wave1.stop();
    _wave2.stop();
    _wave3.stop();
    _pulse.stop();
  }

  void _cleanupListeners() {
    SocketService.instance.off('match_found');
    SocketService.instance.off('queue_left');
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _wave1.dispose();
    _wave2.dispose();
    _wave3.dispose();
    _pulse.dispose();
    _cleanupListeners();
    // Ensure we leave queue if the widget was popped without cancelling
    if (!_matchFound) {
      SocketService.instance.emit('leave_queue');
    }
    super.dispose();
  }

  String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebulaTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // ── Top bar ────────────────────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: NebulaTheme.textSubtle,
                    ),
                    onPressed: _cancelling || _matchFound ? null : _cancel,
                  ),
                  const Spacer(),
                  _GridBadge(gridSize: widget.gridSize),
                ],
              ),
              const SizedBox(height: 16),

              // ── Headline ──────────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _matchFound
                    ? Column(
                        key: const ValueKey('found'),
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => LinearGradient(
                              colors: [
                                Colors.greenAccent.shade400,
                                NebulaTheme.tertiary,
                              ],
                            ).createShader(b),
                            child: const Text(
                              'Tìm thấy đối thủ! 🎉',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đang vào trận đấu...',
                            style: TextStyle(
                              color: NebulaTheme.textSubtle,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('searching'),
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => LinearGradient(
                              colors: [
                                NebulaTheme.primary,
                                NebulaTheme.secondary,
                              ],
                            ).createShader(b),
                            child: const Text(
                              'Đang tìm đối thủ...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hệ thống sẽ ghép bạn với đối thủ tương đương',
                            style: TextStyle(
                              color: NebulaTheme.textSubtle,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 40),

              // ── Radar Animation ───────────────────────────────────────────
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple waves
                    _WaveRing(
                      animation: _wave1,
                      color: _matchFound
                          ? Colors.greenAccent
                          : NebulaTheme.primary,
                    ),
                    _WaveRing(
                      animation: _wave2,
                      color: _matchFound
                          ? Colors.greenAccent
                          : NebulaTheme.primary,
                    ),
                    _WaveRing(
                      animation: _wave3,
                      color: _matchFound
                          ? Colors.greenAccent
                          : NebulaTheme.primary,
                    ),
                    // Center orb
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, child) => Transform.scale(
                        scale: 0.94 + _pulse.value * 0.06,
                        child: child,
                      ),
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _matchFound
                                ? [Colors.greenAccent.shade400, Colors.teal]
                                : [NebulaTheme.primary, NebulaTheme.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_matchFound
                                          ? Colors.greenAccent
                                          : NebulaTheme.primary)
                                      .withValues(alpha: 0.45),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _matchFound
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 44,
                                    key: ValueKey('check'),
                                  )
                                : const Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 40,
                                    key: ValueKey('search'),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── Players Row ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _PlayerChip(
                      label: 'Bạn',
                      isMe: true,
                      color: NebulaTheme.primary,
                      matchFound: _matchFound,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          'VS',
                          style: TextStyle(
                            color: NebulaTheme.secondary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 32,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            gradient: LinearGradient(
                              colors: [
                                NebulaTheme.primary,
                                NebulaTheme.secondary,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _PlayerChip(
                      label: _matchFound ? _opponentName : '???',
                      isMe: false,
                      color: NebulaTheme.secondary,
                      matchFound: _matchFound,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Elapsed / Status ──────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _matchFound
                    ? Container(
                        key: const ValueKey('matched'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_esports_rounded,
                              color: Colors.greenAccent.shade400,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ghép đôi thành công!',
                              style: TextStyle(
                                color: Colors.greenAccent.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        key: const ValueKey('searching'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: NebulaTheme.surfaceHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: NebulaTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Đang tìm kiếm: ${_fmt(_elapsed)}',
                              style: TextStyle(
                                color: NebulaTheme.textSubtle,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const Spacer(),

              // ── Cancel button ─────────────────────────────────────────────
              if (!_matchFound)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _cancelling ? null : _cancel,
                    icon: _cancelling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.close_rounded),
                    label: Text(_cancelling ? 'Đang hủy...' : 'Hủy tìm kiếm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Radar wave ring ───────────────────────────────────────────────────────────
class _WaveRing extends StatelessWidget {
  final AnimationController animation;
  final Color color;

  const _WaveRing({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final t = animation.value;
        final opacity = ((1 - t) * 0.7).clamp(0.0, 1.0);
        return Transform.scale(
          scale: t,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: opacity),
                width: 1.8,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Player chip ───────────────────────────────────────────────────────────────
class _PlayerChip extends StatelessWidget {
  final String label;
  final bool isMe;
  final Color color;
  final bool matchFound;

  const _PlayerChip({
    required this.label,
    required this.isMe,
    required this.color,
    required this.matchFound,
  });

  @override
  Widget build(BuildContext context) {
    final isUnknown = label == '???';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,          // fill the Expanded slot
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: matchFound ? 0.15 : 0.08),
        border: Border.all(
          color: color.withValues(alpha: matchFound ? 0.5 : 0.2),
        ),
        boxShadow: matchFound
            ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,  // always center
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isUnknown
                    ? Icon(
                        Icons.question_mark_rounded,
                        color: color,
                        size: 22,
                        key: const ValueKey('q'),
                      )
                    : Text(
                        label[0].toUpperCase(),
                        key: ValueKey(label),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isMe ? 'Bạn' : (isUnknown ? '???' : label),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Grid size badge ────────────────────────────────────────────────────────────
class _GridBadge extends StatelessWidget {
  final int gridSize;
  const _GridBadge({required this.gridSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: NebulaTheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NebulaTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_on_rounded, color: NebulaTheme.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            '$gridSize×$gridSize',
            style: TextStyle(
              color: NebulaTheme.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
