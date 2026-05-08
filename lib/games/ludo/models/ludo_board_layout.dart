import 'dart:math' as math;

import 'package:flame/components.dart';

import 'ludo_models.dart';

class LudoBoardLayout {
  static const int gridSize = 15;
  static const int sharedRingLength = 52;
  static const int homeLaneStart = 52;
  static const int finishIndex = 57;

  static const Map<LudoPlayerColor, int> startOffsets = {
    LudoPlayerColor.red: 1,
    LudoPlayerColor.green: 14,
    LudoPlayerColor.yellow: 27,
    LudoPlayerColor.blue: 40,
  };

  static const List<int> safeMainIndices = [1, 9, 14, 22, 27, 35, 40, 48];

  static const List<GridPoint> sharedRing = [
    GridPoint(6, 0),
    GridPoint(6, 1),
    GridPoint(6, 2),
    GridPoint(6, 3),
    GridPoint(6, 4),
    GridPoint(6, 5),
    GridPoint(5, 6),
    GridPoint(4, 6),
    GridPoint(3, 6),
    GridPoint(2, 6),
    GridPoint(1, 6),
    GridPoint(0, 6),
    GridPoint(0, 7),
    GridPoint(0, 8),
    GridPoint(1, 8),
    GridPoint(2, 8),
    GridPoint(3, 8),
    GridPoint(4, 8),
    GridPoint(5, 8),
    GridPoint(6, 9),
    GridPoint(6, 10),
    GridPoint(6, 11),
    GridPoint(6, 12),
    GridPoint(6, 13),
    GridPoint(6, 14),
    GridPoint(7, 14),
    GridPoint(8, 14),
    GridPoint(8, 13),
    GridPoint(8, 12),
    GridPoint(8, 11),
    GridPoint(8, 10),
    GridPoint(8, 9),
    GridPoint(9, 8),
    GridPoint(10, 8),
    GridPoint(11, 8),
    GridPoint(12, 8),
    GridPoint(13, 8),
    GridPoint(14, 8),
    GridPoint(14, 7),
    GridPoint(14, 6),
    GridPoint(13, 6),
    GridPoint(12, 6),
    GridPoint(11, 6),
    GridPoint(10, 6),
    GridPoint(9, 6),
    GridPoint(8, 5),
    GridPoint(8, 4),
    GridPoint(8, 3),
    GridPoint(8, 2),
    GridPoint(8, 1),
    GridPoint(8, 0),
    GridPoint(7, 0),
  ];

  static const Map<LudoPlayerColor, List<GridPoint>> homeLanes = {
    LudoPlayerColor.red: [
      GridPoint(7, 1),
      GridPoint(7, 2),
      GridPoint(7, 3),
      GridPoint(7, 4),
      GridPoint(7, 5),
      GridPoint(7, 6),
    ],
    LudoPlayerColor.green: [
      GridPoint(1, 7),
      GridPoint(2, 7),
      GridPoint(3, 7),
      GridPoint(4, 7),
      GridPoint(5, 7),
      GridPoint(6, 7),
    ],
    LudoPlayerColor.yellow: [
      GridPoint(7, 13),
      GridPoint(7, 12),
      GridPoint(7, 11),
      GridPoint(7, 10),
      GridPoint(7, 9),
      GridPoint(7, 8),
    ],
    LudoPlayerColor.blue: [
      GridPoint(13, 7),
      GridPoint(12, 7),
      GridPoint(11, 7),
      GridPoint(10, 7),
      GridPoint(9, 7),
      GridPoint(8, 7),
    ],
  };

  static const Map<LudoPlayerColor, List<GridPoint>> yards = {
    LudoPlayerColor.red: [
      GridPoint(2, 2),
      GridPoint(2, 4),
      GridPoint(4, 2),
      GridPoint(4, 4),
    ],
    LudoPlayerColor.green: [
      GridPoint(2, 10),
      GridPoint(2, 12),
      GridPoint(4, 10),
      GridPoint(4, 12),
    ],
    LudoPlayerColor.yellow: [
      GridPoint(10, 10),
      GridPoint(10, 12),
      GridPoint(12, 10),
      GridPoint(12, 12),
    ],
    LudoPlayerColor.blue: [
      GridPoint(10, 2),
      GridPoint(10, 4),
      GridPoint(12, 2),
      GridPoint(12, 4),
    ],
  };

  static int toMainRingIndex(LudoPlayerColor color, int playerPathIndex) {
    final start = startOffsets[color]!;
    return (start + playerPathIndex) % sharedRingLength;
  }

  static int? mainRingIndexForHorse(HorseState horse) {
    if (!horse.isOnSharedRing) return null;
    return toMainRingIndex(horse.color, horse.positionIndex);
  }

  static PathNode nodeFor(LudoPlayerColor color, int pathIndex) {
    if (pathIndex < 0) {
      return PathNode(
        id: '${color.name}-yard',
        grid: yards[color]!.first,
        kind: PathNodeKind.yard,
        owner: color,
      );
    }

    if (pathIndex < homeLaneStart) {
      final mainIndex = toMainRingIndex(color, pathIndex);
      return PathNode(
        id: 'main-$mainIndex',
        grid: sharedRing[mainIndex],
        kind: safeMainIndices.contains(mainIndex)
            ? PathNodeKind.safe
            : PathNodeKind.main,
      );
    }

    final laneIndex = pathIndex - homeLaneStart;
    final lane = homeLanes[color]!;
    final grid = lane[math.min(laneIndex, lane.length - 1)];
    return PathNode(
      id: '${color.name}-home-$laneIndex',
      grid: grid,
      kind: pathIndex == finishIndex ? PathNodeKind.finish : PathNodeKind.homeLane,
      owner: color,
    );
  }

  static GridPoint gridForHorse(HorseState horse) {
    if (horse.isInYard) return yards[horse.color]![horse.slot];
    return nodeFor(horse.color, horse.positionIndex).grid;
  }

  static List<PathNode> traversalNodes({
    required LudoPlayerColor color,
    required int fromPosition,
    required int toPosition,
  }) {
    if (fromPosition == toPosition) return [nodeFor(color, toPosition)];
    final start = fromPosition < 0 ? 0 : fromPosition + 1;
    return [
      for (var index = start; index <= toPosition; index++)
        nodeFor(color, index),
    ];
  }

  static Vector2 boardOrigin(Vector2 gameSize) {
    final boardSize = math.min(gameSize.x, gameSize.y);
    return Vector2((gameSize.x - boardSize) / 2, (gameSize.y - boardSize) / 2);
  }

  static double cellSize(Vector2 gameSize) {
    return math.min(gameSize.x, gameSize.y) / gridSize;
  }

  static Vector2 centerForGrid(Vector2 gameSize, GridPoint grid) {
    final cell = cellSize(gameSize);
    final origin = boardOrigin(gameSize);
    return Vector2(
      origin.x + (grid.col + 0.5) * cell,
      origin.y + (grid.row + 0.5) * cell,
    );
  }
}
