import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Path;

import '../models/ludo_board_layout.dart';
import '../models/ludo_models.dart';

class LudoBoard extends PositionComponent {
  LudoBoard();

  final Paint _linePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.14)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final boardSize = size.x;
    final cell = boardSize / LudoBoardLayout.gridSize;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, boardSize, boardSize),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFF17133F),
    );

    _drawHomeQuadrant(canvas, cell, LudoPlayerColor.red, 0, 0);
    _drawHomeQuadrant(canvas, cell, LudoPlayerColor.green, 9, 0);
    _drawHomeQuadrant(canvas, cell, LudoPlayerColor.blue, 0, 9);
    _drawHomeQuadrant(canvas, cell, LudoPlayerColor.yellow, 9, 9);
    _drawPathCells(canvas, cell);
    _drawCenter(canvas, cell);
    _drawGridLines(canvas, cell);
  }

  void _drawHomeQuadrant(
    Canvas canvas,
    double cell,
    LudoPlayerColor color,
    int col,
    int row,
  ) {
    final rect = Rect.fromLTWH(col * cell, row * cell, cell * 6, cell * 6);
    canvas.drawRect(rect, Paint()..color = color.paint.withValues(alpha: 0.22));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(cell * 0.75),
        Radius.circular(cell * 0.45),
      ),
      Paint()..color = const Color(0xFF211D52),
    );

    for (final yard in LudoBoardLayout.yards[color]!) {
      canvas.drawCircle(
        Offset((yard.col + 0.5) * cell, (yard.row + 0.5) * cell),
        cell * 0.42,
        Paint()..color = color.paint.withValues(alpha: 0.48),
      );
    }
  }

  void _drawPathCells(Canvas canvas, double cell) {
    for (var i = 0; i < LudoBoardLayout.sharedRing.length; i++) {
      final grid = LudoBoardLayout.sharedRing[i];
      final color = _startColorForMainIndex(i);
      final rect = Rect.fromLTWH(grid.col * cell, grid.row * cell, cell, cell);
      canvas.drawRect(
        rect.deflate(1),
        Paint()
          ..color = color?.paint.withValues(alpha: 0.54) ??
              const Color(0xFFEFEAFE).withValues(alpha: 0.92),
      );
      if (LudoBoardLayout.safeMainIndices.contains(i)) {
        _drawSafeStar(canvas, rect.center, cell * 0.28);
      }
    }

    for (final entry in LudoBoardLayout.homeLanes.entries) {
      for (final grid in entry.value) {
        final rect = Rect.fromLTWH(grid.col * cell, grid.row * cell, cell, cell);
        canvas.drawRect(
          rect.deflate(1),
          Paint()..color = entry.key.paint.withValues(alpha: 0.62),
        );
      }
    }
  }

  void _drawCenter(Canvas canvas, double cell) {
    final center = Offset(7.5 * cell, 7.5 * cell);
    final path = Path()
      ..moveTo(6 * cell, 6 * cell)
      ..lineTo(9 * cell, 6 * cell)
      ..lineTo(9 * cell, 9 * cell)
      ..lineTo(6 * cell, 9 * cell)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF211D52));
    canvas.drawCircle(
      center,
      cell * 0.68,
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );
  }

  void _drawGridLines(Canvas canvas, double cell) {
    for (var index = 0; index <= LudoBoardLayout.gridSize; index++) {
      final offset = index * cell;
      canvas.drawLine(Offset(offset, 0), Offset(offset, size.y), _linePaint);
      canvas.drawLine(Offset(0, offset), Offset(size.x, offset), _linePaint);
    }
  }

  void _drawSafeStar(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -1.5708 + i * 0.6283;
      final r = i.isEven ? radius : radius * 0.45;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF17133F));
  }

  LudoPlayerColor? _startColorForMainIndex(int index) {
    for (final entry in LudoBoardLayout.startOffsets.entries) {
      if (entry.value == index) return entry.key;
    }
    return null;
  }
}
