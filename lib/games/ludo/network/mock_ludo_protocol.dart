import 'dart:async';

import '../models/ludo_models.dart';
import '../rules/ludo_rules_engine.dart';
import 'base_game_protocol.dart';

class MockLudoProtocol implements BaseGameProtocol {
  MockLudoProtocol({
    LudoGameSnapshot? initialState,
    LudoRulesEngine? rules,
  })  : _rules = rules ?? LudoRulesEngine(),
        _snapshot = initialState ?? createInitialLudoSnapshot() {
    Timer.run(() => _stateController.add(_snapshot));
  }

  final LudoRulesEngine _rules;
  final _stateController = StreamController<LudoGameSnapshot>.broadcast();
  LudoGameSnapshot _snapshot;

  @override
  Stream<LudoGameSnapshot> get stateUpdates => _stateController.stream;

  @override
  void sendRollDice() {
    if (_snapshot.phase != LudoGamePhase.waitingForRoll) return;

    _snapshot = _snapshot.copyWith(
      phase: LudoGamePhase.animatingRoll,
      revision: _snapshot.revision + 1,
      clearLastMove: true,
    );
    _stateController.add(_snapshot);

    Future<void>.delayed(const Duration(milliseconds: 450), () {
      final diceValue = _rules.rollDice();
      _snapshot = _rules.applyRoll(_snapshot, diceValue);
      _stateController.add(_snapshot);
    });
  }

  @override
  void sendMoveHorse(String horseId) {
    if (_snapshot.phase != LudoGamePhase.waitingForMoveSelection) return;

    _snapshot = _snapshot.copyWith(
      phase: LudoGamePhase.animatingMove,
      revision: _snapshot.revision + 1,
    );
    _stateController.add(_snapshot);

    Future<void>.delayed(const Duration(milliseconds: 160), () {
      _snapshot = _rules.applyMove(_snapshot, horseId);
      _stateController.add(_snapshot);
    });
  }

  @override
  void dispose() {
    _stateController.close();
  }
}
