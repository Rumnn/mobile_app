import 'package:flutter/material.dart';

import '../../widgets/nebula_theme.dart';

/// A single puzzle tile widget that animates smoothly to its position.
///
/// Uses [AnimatedPositioned] inside a [Stack] for smooth 250ms transitions
/// when tiles slide into the empty slot.
class PuzzleTile extends StatelessWidget {
  final int value;
  final int index;
  final int gridSize;
  final double tileSize;
  final double spacing;
  final VoidCallback onTap;
  final bool canMove;

  const PuzzleTile({
    super.key,
    required this.value,
    required this.index,
    required this.gridSize,
    required this.tileSize,
    required this.spacing,
    required this.onTap,
    required this.canMove,
  });

  @override
  Widget build(BuildContext context) {
    final row = index ~/ gridSize;
    final col = index % gridSize;
    final left = col * (tileSize + spacing);
    final top = row * (tileSize + spacing);

    // Empty slot — render nothing
    if (value == 0) {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        left: left,
        top: top,
        width: tileSize,
        height: tileSize,
        child: const SizedBox.shrink(),
      );
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: tileSize,
      height: tileSize,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tileSize * 0.18),
            gradient: canMove
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6C47FF),
                      Color(0xFF9F7AFF),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      NebulaTheme.surfaceHigh,
                      NebulaTheme.surfaceHigh.withValues(alpha: 0.85),
                    ],
                  ),
            border: Border.all(
              color: canMove
                  ? NebulaTheme.primary.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              if (canMove)
                BoxShadow(
                  color: NebulaTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                color: canMove ? Colors.white : NebulaTheme.text,
                fontSize: tileSize * 0.36,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
