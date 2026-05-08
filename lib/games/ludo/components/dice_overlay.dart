import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../models/ludo_models.dart';

typedef RollTapHandler = void Function();

class DiceOverlay extends PositionComponent with TapCallbacks {
  DiceOverlay({required this.onRoll}) : super(anchor: Anchor.topLeft);

  RollTapHandler onRoll;
  LudoGameSnapshot? snapshot;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Offset.zero & Size(size.x, size.y);
    final background = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.drawRRect(
      background,
      Paint()..color = const Color(0xFF211D52).withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      background,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final current = snapshot?.currentPlayer;
    _paintText(
      canvas,
      current == null ? 'Waiting' : '${current.color.label} turn',
      const Offset(12, 10),
      14,
      current?.color.paint ?? Colors.white,
      FontWeight.w800,
    );

    final diceValue = snapshot?.diceValue;
    final phase = snapshot?.phase;
    final diceLabel = phase == LudoGamePhase.animatingRoll
        ? '...'
        : diceValue == null
            ? '-'
            : '$diceValue';
    _paintText(
      canvas,
      diceLabel,
      Offset(size.x - 56, 4),
      36,
      Colors.white,
      FontWeight.w900,
    );

    final canRoll = phase == LudoGamePhase.waitingForRoll;
    _paintText(
      canvas,
      canRoll ? 'Tap to roll' : _phaseLabel(phase),
      const Offset(12, 36),
      12,
      canRoll ? Colors.white : Colors.white.withValues(alpha: 0.62),
      FontWeight.w600,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (snapshot?.phase == LudoGamePhase.waitingForRoll) onRoll();
    event.handled = true;
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - offset.dx - 8);
    painter.paint(canvas, offset);
  }

  String _phaseLabel(LudoGamePhase? phase) {
    switch (phase) {
      case LudoGamePhase.waitingForMoveSelection:
        return 'Choose a horse';
      case LudoGamePhase.animatingMove:
        return 'Moving';
      case LudoGamePhase.turnTransition:
        return 'Next turn';
      case LudoGamePhase.gameFinished:
        return 'Finished';
      case LudoGamePhase.animatingRoll:
        return 'Rolling';
      case LudoGamePhase.waitingForRoll:
      case null:
        return 'Waiting';
    }
  }
}
