import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/games/ludo/models/ludo_board_layout.dart';
import 'package:mobile_app/games/ludo/models/ludo_models.dart';
import 'package:mobile_app/games/ludo/rules/ludo_rules_engine.dart';

void main() {
  test('maps private movement indices onto shared 15x15 board coordinates', () {
    final redStart = LudoBoardLayout.nodeFor(LudoPlayerColor.red, 0);
    final blueStart = LudoBoardLayout.nodeFor(LudoPlayerColor.blue, 0);

    expect(redStart.grid, const GridPoint(6, 1));
    expect(blueStart.grid, const GridPoint(13, 6));
    expect(LudoBoardLayout.nodeFor(LudoPlayerColor.red, 52).grid,
        const GridPoint(7, 1));
    expect(LudoBoardLayout.nodeFor(LudoPlayerColor.red, 57).kind,
        PathNodeKind.finish);
  });

  test('requires a six to enter from yard and exact roll to finish', () {
    final rules = LudoRulesEngine();
    final horse = HorseState(
      id: 'red-0',
      playerId: 'player-0',
      color: LudoPlayerColor.red,
      slot: 0,
      positionIndex: -1,
    );

    expect(rules.canMove(horse, 5), isFalse);
    expect(rules.canMove(horse, 6), isTrue);
    expect(rules.canMove(horse.copyWith(positionIndex: 55), 3), isFalse);
    expect(rules.canMove(horse.copyWith(positionIndex: 55), 2), isTrue);
  });

  test('captures opponents on unsafe shared cells', () {
    final rules = LudoRulesEngine();
    final snapshot = createInitialLudoSnapshot().copyWith(
      diceValue: 2,
      phase: LudoGamePhase.waitingForMoveSelection,
      players: [
        LudoPlayerState(
          id: 'player-0',
          name: 'Red',
          color: LudoPlayerColor.red,
          horses: [
            const HorseState(
              id: 'red-0',
              playerId: 'player-0',
              color: LudoPlayerColor.red,
              slot: 0,
              positionIndex: 0,
            ),
          ],
        ),
        LudoPlayerState(
          id: 'player-1',
          name: 'Blue',
          color: LudoPlayerColor.blue,
          horses: [
            const HorseState(
              id: 'blue-0',
              playerId: 'player-1',
              color: LudoPlayerColor.blue,
              slot: 0,
              positionIndex: 15,
            ),
          ],
        ),
      ],
    );

    final updated = rules.applyMove(snapshot, 'red-0');

    expect(updated.horseById('red-0')?.positionIndex, 2);
    expect(updated.horseById('blue-0')?.positionIndex, -1);
    expect(updated.lastMove?.capturedHorseIds, ['blue-0']);
  });
}
