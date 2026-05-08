import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../models/ludo_models.dart';

typedef HorseTapHandler = void Function(String horseId);

class Horse extends PositionComponent with TapCallbacks {
  Horse({
    required this.state,
    required this.onTap,
  }) : super(anchor: Anchor.center);

  HorseState state;
  HorseTapHandler onTap;
  bool selectable = false;

  final List<Vector2> _targets = [];
  Completer<void>? _moveCompleter;
  double _speed = 320;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final radius = size.x / 2;
    final center = Offset(radius, radius);
    final color = state.color.paint;

    if (selectable) {
      canvas.drawCircle(
        center,
        radius * 0.98,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    canvas.drawCircle(
      center.translate(0, radius * 0.12),
      radius * 0.78,
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawCircle(center, radius * 0.78, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius * 0.48,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${state.slot + 1}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_targets.isEmpty) return;

    final target = _targets.first;
    final delta = target - position;
    final distance = delta.length;
    final step = _speed * dt;

    if (distance <= step) {
      position = target;
      _targets.removeAt(0);
      if (_targets.isEmpty) {
        _moveCompleter?.complete();
        _moveCompleter = null;
      }
      return;
    }

    position += delta.normalized() * step;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (selectable) onTap(state.id);
    event.handled = true;
  }

  Future<void> animateAlong(List<Vector2> positions, {double speed = 320}) {
    _targets
      ..clear()
      ..addAll(positions.map((point) => point.clone()));
    _speed = speed;
    _moveCompleter?.complete();
    _moveCompleter = Completer<void>();
    if (_targets.isEmpty) {
      _moveCompleter!.complete();
    }
    return _moveCompleter!.future;
  }
}
