import 'dart:math';

import '../models/ludo_board_layout.dart';
import '../models/ludo_models.dart';

class LudoRulesEngine {
  LudoRulesEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  int rollDice() => _random.nextInt(6) + 1;

  bool canMove(HorseState horse, int diceValue) {
    if (horse.isFinished) return false;
    if (horse.isInYard) return diceValue == 6;
    return horse.positionIndex + diceValue <= LudoBoardLayout.finishIndex;
  }

  List<String> legalHorseIds(LudoGameSnapshot snapshot) {
    final diceValue = snapshot.diceValue;
    if (diceValue == null) return const [];
    return snapshot.currentPlayer.horses
        .where((horse) => canMove(horse, diceValue))
        .map((horse) => horse.id)
        .toList();
  }

  LudoGameSnapshot applyRoll(LudoGameSnapshot snapshot, int diceValue) {
    final rolled = snapshot.copyWith(
      diceValue: diceValue,
      phase: LudoGamePhase.waitingForMoveSelection,
      revision: snapshot.revision + 1,
      clearLastMove: true,
    );

    if (legalHorseIds(rolled).isNotEmpty) return rolled;

    return rolled.copyWith(
      currentTurnIndex: _nextTurnIndex(rolled),
      phase: LudoGamePhase.waitingForRoll,
      revision: rolled.revision + 1,
    );
  }

  LudoGameSnapshot applyMove(LudoGameSnapshot snapshot, String horseId) {
    final diceValue = snapshot.diceValue;
    if (diceValue == null) return snapshot;

    final currentPlayer = snapshot.currentPlayer;
    final movingHorse = _horseById(currentPlayer.horses, horseId);
    if (movingHorse == null || !canMove(movingHorse, diceValue)) {
      return snapshot;
    }

    final from = movingHorse.positionIndex;
    final to = movingHorse.isInYard ? 0 : from + diceValue;
    final movedHorse = movingHorse.copyWith(positionIndex: to);
    final capturedHorseIds = <String>[];

    final updatedPlayers = snapshot.players.map((player) {
      final updatedHorses = player.horses.map((horse) {
        if (horse.id == horseId) return movedHorse;
        return horse;
      }).toList();
      return player.copyWith(horses: updatedHorses);
    }).toList();

    final movedSnapshot = snapshot.copyWith(players: updatedPlayers);
    final captureTarget = _captureTarget(movedSnapshot, movedHorse);
    final capturedPlayers = movedSnapshot.players.map((player) {
      final updatedHorses = player.horses.map((horse) {
        if (horse.id == captureTarget?.id) {
          capturedHorseIds.add(horse.id);
          return horse.copyWith(positionIndex: -1);
        }
        return horse;
      }).toList();
      return player.copyWith(horses: updatedHorses);
    }).toList();

    final finalPlayers = capturedPlayers;
    final playerAfterMove = finalPlayers
        .firstWhere((player) => player.id == currentPlayer.id);
    final winnerId = playerAfterMove.hasFinished ? playerAfterMove.id : null;
    final shouldKeepTurn = diceValue == 6 && winnerId == null;

    return snapshot.copyWith(
      players: finalPlayers,
      currentTurnIndex: shouldKeepTurn ? snapshot.currentTurnIndex : _nextTurnIndex(snapshot),
      phase: winnerId == null
          ? LudoGamePhase.waitingForRoll
          : LudoGamePhase.gameFinished,
      revision: snapshot.revision + 1,
      lastMove: LudoMoveRecord(
        horseId: horseId,
        playerId: currentPlayer.id,
        fromPosition: from,
        toPosition: to,
        diceValue: diceValue,
        capturedHorseIds: capturedHorseIds,
      ),
      winnerPlayerId: winnerId,
    );
  }

  HorseState? _captureTarget(LudoGameSnapshot snapshot, HorseState movedHorse) {
    if (!movedHorse.isOnSharedRing) return null;

    final mainIndex = LudoBoardLayout.mainRingIndexForHorse(movedHorse);
    if (mainIndex == null ||
        LudoBoardLayout.safeMainIndices.contains(mainIndex)) {
      return null;
    }

    for (final horse in snapshot.allHorses) {
      if (horse.id == movedHorse.id ||
          horse.playerId == movedHorse.playerId ||
          !horse.isOnSharedRing) {
        continue;
      }
      if (LudoBoardLayout.mainRingIndexForHorse(horse) == mainIndex) {
        return horse;
      }
    }
    return null;
  }

  int _nextTurnIndex(LudoGameSnapshot snapshot) {
    return (snapshot.currentTurnIndex + 1) % snapshot.players.length;
  }

  HorseState? _horseById(List<HorseState> horses, String horseId) {
    for (final horse in horses) {
      if (horse.id == horseId) return horse;
    }
    return null;
  }
}

LudoGameSnapshot createInitialLudoSnapshot({
  String matchId = 'local-ludo-room',
  int playerCount = 4,
}) {
  final colors = [
    LudoPlayerColor.red,
    LudoPlayerColor.blue,
    LudoPlayerColor.green,
    LudoPlayerColor.yellow,
  ].take(playerCount).toList();

  final players = <LudoPlayerState>[
    for (var playerIndex = 0; playerIndex < colors.length; playerIndex++)
      LudoPlayerState(
        id: 'player-$playerIndex',
        name: colors[playerIndex].label,
        color: colors[playerIndex],
        horses: [
          for (var slot = 0; slot < 4; slot++)
            HorseState(
              id: '${colors[playerIndex].name}-$slot',
              playerId: 'player-$playerIndex',
              color: colors[playerIndex],
              slot: slot,
              positionIndex: -1,
            ),
        ],
      ),
  ];

  return LudoGameSnapshot(
    matchId: matchId,
    players: players,
    currentTurnIndex: 0,
    phase: LudoGamePhase.waitingForRoll,
    revision: 0,
  );
}
