import 'package:flutter/material.dart';

import '../../widgets/nebula_theme.dart';
import 'puzzle_controller.dart';
import 'puzzle_tile.dart';

/// The puzzle board widget that renders tiles inside a [Stack].
///
/// Each numbered tile is an [AnimatedPositioned] so only the moving tile
/// rebuilds — the rest of the board stays static.  The board sizes itself
/// responsively based on the available width (capped at a max size).
class PuzzleBoard extends StatelessWidget {
  final PuzzleController controller;
  final double maxBoardSize;

  const PuzzleBoard({
    super.key,
    required this.controller,
    this.maxBoardSize = 420,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing — fit within parent, max out at maxBoardSize
        final available = constraints.maxWidth.clamp(0.0, maxBoardSize);
        const spacing = 6.0;
        final gridSize = controller.gridSize;
        final tileSize =
            (available - spacing * (gridSize - 1)) / gridSize;
        final boardSize = available;

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: NebulaTheme.background.withValues(alpha: 0.5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: _buildTiles(gridSize, tileSize, spacing),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTiles(int gridSize, double tileSize, double spacing) {
    final tiles = controller.tiles;
    final widgets = <Widget>[];

    for (int i = 0; i < tiles.length; i++) {
      final value = tiles[i];
      widgets.add(
        PuzzleTile(
          key: ValueKey(value), // keyed by value so AnimatedPositioned works
          value: value,
          index: i,
          gridSize: gridSize,
          tileSize: tileSize,
          spacing: spacing,
          canMove: controller.canMove(i),
          onTap: () => controller.moveTile(i),
        ),
      );
    }

    return widgets;
  }
}
