import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'components/dice_overlay.dart';
import 'components/horse.dart';
import 'components/ludo_board.dart';
import 'models/ludo_board_layout.dart';
import 'models/ludo_models.dart';
import 'network/base_game_protocol.dart';
import 'rules/ludo_rules_engine.dart';

class LudoGame extends FlameGame {
  LudoGame({required BaseGameProtocol protocol})
      : _protocol = protocol,
        _diceOverlay = DiceOverlay(onRoll: protocol.sendRollDice);

  final BaseGameProtocol _protocol;
  final LudoRulesEngine _rules = LudoRulesEngine();
  final Map<String, Horse> _horseComponents = {};
  final LudoBoard _board = LudoBoard();
  final DiceOverlay _diceOverlay;
  StreamSubscription<LudoGameSnapshot>? _subscription;
  LudoGameSnapshot? _snapshot;
  int _lastRevision = -1;

  @override
  Color backgroundColor() => const Color(0xFF0F0B3C);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_board);
    add(_diceOverlay);

    _subscription = _protocol.stateUpdates.listen(onServerStateUpdate);
  }

  void onServerStateUpdate(LudoGameSnapshot gameState) {
    if (gameState.revision <= _lastRevision) return;
    _lastRevision = gameState.revision;

    final previous = _snapshot;
    _snapshot = gameState;
    _diceOverlay.snapshot = gameState;
    _reconstructHorseComponents(gameState);
    _resizeComponents();

    final lastMove = gameState.lastMove;
    final shouldAnimate = lastMove != null &&
        previous?.horseById(lastMove.horseId)?.positionIndex ==
            lastMove.fromPosition;

    if (shouldAnimate) {
      _animateCanonicalMove(gameState, lastMove);
    } else {
      _layoutHorses(gameState);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _resizeComponents();
    final snapshot = _snapshot;
    if (snapshot != null) _layoutHorses(snapshot);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    _protocol.dispose();
    super.onRemove();
  }

  void _reconstructHorseComponents(LudoGameSnapshot snapshot) {
    final snapshotHorseIds = snapshot.allHorses.map((horse) => horse.id).toSet();
    final staleIds = _horseComponents.keys
        .where((horseId) => !snapshotHorseIds.contains(horseId))
        .toList();
    for (final horseId in staleIds) {
      _horseComponents.remove(horseId)?.removeFromParent();
    }

    final legalHorseIds = _rules.legalHorseIds(snapshot).toSet();
    for (final horseState in snapshot.allHorses) {
      final component = _horseComponents.putIfAbsent(horseState.id, () {
        final horse = Horse(
          state: horseState,
          onTap: _protocol.sendMoveHorse,
        );
        add(horse);
        return horse;
      });
      component.state = horseState;
      component.selectable =
          snapshot.phase == LudoGamePhase.waitingForMoveSelection &&
              horseState.playerId == snapshot.currentPlayer.id &&
              legalHorseIds.contains(horseState.id);
    }
  }

  void _resizeComponents() {
    if (size.x <= 0 || size.y <= 0) return;
    final boardSize = math.min(size.x, size.y);
    _board
      ..position = LudoBoardLayout.boardOrigin(size)
      ..size = Vector2.all(boardSize);

    final overlayWidth = math.min(size.x - 24, 190).toDouble();
    _diceOverlay
      ..position = Vector2(12, 12)
      ..size = Vector2(overlayWidth, 72);

    final horseSize = LudoBoardLayout.cellSize(size) * 0.78;
    for (final horse in _horseComponents.values) {
      horse.size = Vector2.all(horseSize);
    }
  }

  void _layoutHorses(LudoGameSnapshot snapshot) {
    final grouped = <String, List<HorseState>>{};
    for (final horse in snapshot.allHorses) {
      final grid = LudoBoardLayout.gridForHorse(horse);
      grouped.putIfAbsent('${grid.row}:${grid.col}', () => []).add(horse);
    }

    for (final group in grouped.values) {
      for (var i = 0; i < group.length; i++) {
        final horse = group[i];
        final component = _horseComponents[horse.id];
        if (component == null) continue;
        component.position = _positionForHorse(horse, stackIndex: i, stackSize: group.length);
      }
    }
  }

  Future<void> _animateCanonicalMove(
    LudoGameSnapshot snapshot,
    LudoMoveRecord move,
  ) async {
    final movedState = snapshot.horseById(move.horseId);
    final component = _horseComponents[move.horseId];
    if (movedState == null || component == null) {
      _layoutHorses(snapshot);
      return;
    }

    final startState = movedState.copyWith(positionIndex: move.fromPosition);
    component.position = _positionForHorse(startState);
    final traversal = LudoBoardLayout.traversalNodes(
      color: movedState.color,
      fromPosition: move.fromPosition,
      toPosition: move.toPosition,
    );
    final points = traversal
        .map((node) => LudoBoardLayout.centerForGrid(size, node.grid))
        .toList();

    await component.animateAlong(points);
    _layoutHorses(snapshot);
  }

  Vector2 _positionForHorse(
    HorseState horse, {
    int stackIndex = 0,
    int stackSize = 1,
  }) {
    final grid = LudoBoardLayout.gridForHorse(horse);
    final center = LudoBoardLayout.centerForGrid(size, grid);
    if (stackSize <= 1) return center;

    final radius = LudoBoardLayout.cellSize(size) * 0.18;
    final angle = (math.pi * 2 * stackIndex) / stackSize;
    return center + Vector2(math.cos(angle) * radius, math.sin(angle) * radius);
  }
}
