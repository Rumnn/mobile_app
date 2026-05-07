import 'package:flutter/material.dart';

import '../../widgets/nebula_theme.dart';
import 'puzzle_board.dart';
import 'puzzle_controller.dart';

/// Top-level reusable widget for the Sliding Puzzle mini-game.
///
/// Drop this into any screen:
/// ```dart
/// const SlidingPuzzleGame()
/// ```
///
/// It is fully self-contained — owns its own [PuzzleController] and manages
/// layout, HUD (moves + timer), difficulty toggle, restart, and victory dialog.
class SlidingPuzzleGame extends StatefulWidget {
  const SlidingPuzzleGame({super.key});

  @override
  State<SlidingPuzzleGame> createState() => _SlidingPuzzleGameState();
}

class _SlidingPuzzleGameState extends State<SlidingPuzzleGame>
    with SingleTickerProviderStateMixin {
  late PuzzleController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _controller = PuzzleController(gridSize: 3)..addListener(_onStateChange);

    // Pulsing animation for the timer when running
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _onStateChange() {
    setState(() {});
    if (_controller.won) {
      _pulseController.stop();
      // Show victory dialog after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showVictoryDialog();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChange);
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Victory Dialog ──────────────────────────────────────────────────────

  void _showVictoryDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Victory',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, a1, a2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: a1, child: child),
        );
      },
      pageBuilder: (ctx, a1, a2) {
        return Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1A52),
                  Color(0xFF2A1F6E),
                ],
              ),
              border: Border.all(
                color: NebulaTheme.primary.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: NebulaTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 48,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Trophy icon with glow
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          NebulaTheme.secondary.withValues(alpha: 0.3),
                          NebulaTheme.primary.withValues(alpha: 0.15),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NebulaTheme.secondary.withValues(alpha: 0.4),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: NebulaTheme.secondary,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '🎉 VICTORY!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puzzle Solved',
                    style: TextStyle(
                      color: NebulaTheme.textSubtle,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statColumn(
                        Icons.touch_app_rounded,
                        '${_controller.moves}',
                        'Moves',
                        NebulaTheme.primary,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _statColumn(
                        Icons.timer_rounded,
                        _controller.formattedTime,
                        'Time',
                        NebulaTheme.tertiary,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _statColumn(
                        Icons.grid_on_rounded,
                        '${_controller.gridSize}×${_controller.gridSize}',
                        'Grid',
                        NebulaTheme.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Play Again button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _controller.shuffle();
                        _pulseController.repeat(reverse: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NebulaTheme.primary,
                        foregroundColor: NebulaTheme.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Play Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statColumn(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: NebulaTheme.textSubtle,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            _buildHeader(),
            const SizedBox(height: 16),
            // ── HUD: Moves + Timer ──
            _buildHud(),
            const SizedBox(height: 20),
            // ── Difficulty Toggle ──
            _buildDifficultyToggle(),
            const SizedBox(height: 20),
            // ── Board ──
            Flexible(
              child: AspectRatio(
                aspectRatio: 1,
                child: PuzzleBoard(controller: _controller),
              ),
            ),
            const SizedBox(height: 20),
            // ── Restart Button ──
            _buildRestartButton(),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                NebulaTheme.primary.withValues(alpha: 0.3),
                NebulaTheme.tertiary.withValues(alpha: 0.15),
              ],
            ),
          ),
          child: const Icon(
            Icons.extension_rounded,
            color: NebulaTheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sliding Puzzle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Arrange tiles in order',
              style: TextStyle(
                color: NebulaTheme.textSubtle,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: NebulaTheme.surfaceHigh.withValues(alpha: 0.6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Moves
          _hudItem(
            icon: Icons.touch_app_rounded,
            label: 'MOVES',
            value: '${_controller.moves}',
            color: NebulaTheme.primary,
          ),
          // Divider
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          // Timer
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return _hudItem(
                icon: Icons.timer_rounded,
                label: 'TIME',
                value: _controller.formattedTime,
                color: _controller.started && !_controller.won
                    ? NebulaTheme.tertiary.withValues(alpha: _pulseAnim.value)
                    : NebulaTheme.tertiary,
              );
            },
          ),
          // Divider
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          // Grid size
          _hudItem(
            icon: Icons.grid_on_rounded,
            label: 'GRID',
            value: '${_controller.gridSize}×${_controller.gridSize}',
            color: NebulaTheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _hudItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: NebulaTheme.textSubtle,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: NebulaTheme.surfaceHigh.withValues(alpha: 0.4),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _difficultyTab(3, 'Easy 3×3'),
          const SizedBox(width: 4),
          _difficultyTab(4, 'Hard 4×4'),
        ],
      ),
    );
  }

  Widget _difficultyTab(int size, String label) {
    final isActive = _controller.gridSize == size;
    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.setGridSize(size),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      NebulaTheme.primary.withValues(alpha: 0.35),
                      NebulaTheme.primary.withValues(alpha: 0.15),
                    ],
                  )
                : null,
            border: isActive
                ? Border.all(
                    color: NebulaTheme.primary.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : NebulaTheme.textSubtle,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestartButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          _controller.shuffle();
          _pulseController.repeat(reverse: true);
        },
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text(
          'Shuffle & Restart',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: NebulaTheme.surfaceHigh,
          foregroundColor: NebulaTheme.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
