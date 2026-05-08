import 'package:flutter/material.dart';

enum LudoPlayerColor {
  red,
  blue,
  green,
  yellow;

  Color get paint {
    switch (this) {
      case LudoPlayerColor.red:
        return const Color(0xFFE84855);
      case LudoPlayerColor.blue:
        return const Color(0xFF2F80ED);
      case LudoPlayerColor.green:
        return const Color(0xFF27AE60);
      case LudoPlayerColor.yellow:
        return const Color(0xFFF2C94C);
    }
  }

  String get label => name[0].toUpperCase() + name.substring(1);
}

enum LudoGamePhase {
  waitingForRoll,
  animatingRoll,
  waitingForMoveSelection,
  animatingMove,
  turnTransition,
  gameFinished,
}

enum PathNodeKind { main, safe, homeLane, finish, yard }

class GridPoint {
  const GridPoint(this.row, this.col);

  final int row;
  final int col;

  @override
  bool operator ==(Object other) {
    return other is GridPoint && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}

class PathNode {
  const PathNode({
    required this.id,
    required this.grid,
    required this.kind,
    this.owner,
  });

  final String id;
  final GridPoint grid;
  final PathNodeKind kind;
  final LudoPlayerColor? owner;

  bool get isSafe => kind == PathNodeKind.safe;
}

class HorseState {
  const HorseState({
    required this.id,
    required this.playerId,
    required this.color,
    required this.slot,
    required this.positionIndex,
  });

  final String id;
  final String playerId;
  final LudoPlayerColor color;
  final int slot;

  /// -1 means yard. 0-51 is that player's view of the shared ring.
  /// 52-57 is the player's home lane, with 57 as finished.
  final int positionIndex;

  bool get isInYard => positionIndex < 0;
  bool get isFinished => positionIndex == 57;
  bool get isOnSharedRing => positionIndex >= 0 && positionIndex <= 51;
  bool get isInHomeLane => positionIndex >= 52 && positionIndex <= 57;

  HorseState copyWith({int? positionIndex}) {
    return HorseState(
      id: id,
      playerId: playerId,
      color: color,
      slot: slot,
      positionIndex: positionIndex ?? this.positionIndex,
    );
  }

  factory HorseState.fromJson(Map<String, dynamic> json) {
    return HorseState(
      id: json['id'] as String,
      playerId: json['playerId'] as String,
      color: LudoPlayerColor.values.byName(json['color'] as String),
      slot: json['slot'] as int,
      positionIndex: json['positionIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerId': playerId,
      'color': color.name,
      'slot': slot,
      'positionIndex': positionIndex,
    };
  }
}

class LudoPlayerState {
  const LudoPlayerState({
    required this.id,
    required this.name,
    required this.color,
    required this.horses,
  });

  final String id;
  final String name;
  final LudoPlayerColor color;
  final List<HorseState> horses;

  bool get hasFinished => horses.every((horse) => horse.isFinished);

  LudoPlayerState copyWith({List<HorseState>? horses}) {
    return LudoPlayerState(
      id: id,
      name: name,
      color: color,
      horses: horses ?? this.horses,
    );
  }

  factory LudoPlayerState.fromJson(Map<String, dynamic> json) {
    return LudoPlayerState(
      id: json['id'] as String,
      name: json['name'] as String,
      color: LudoPlayerColor.values.byName(json['color'] as String),
      horses: (json['horses'] as List<dynamic>)
          .map((horse) => HorseState.fromJson(horse as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.name,
      'horses': horses.map((horse) => horse.toJson()).toList(),
    };
  }
}

class LudoMoveRecord {
  const LudoMoveRecord({
    required this.horseId,
    required this.playerId,
    required this.fromPosition,
    required this.toPosition,
    required this.diceValue,
    this.capturedHorseIds = const [],
  });

  final String horseId;
  final String playerId;
  final int fromPosition;
  final int toPosition;
  final int diceValue;
  final List<String> capturedHorseIds;

  factory LudoMoveRecord.fromJson(Map<String, dynamic> json) {
    return LudoMoveRecord(
      horseId: json['horseId'] as String,
      playerId: json['playerId'] as String,
      fromPosition: json['fromPosition'] as int,
      toPosition: json['toPosition'] as int,
      diceValue: json['diceValue'] as int,
      capturedHorseIds: (json['capturedHorseIds'] as List<dynamic>? ?? [])
          .cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horseId': horseId,
      'playerId': playerId,
      'fromPosition': fromPosition,
      'toPosition': toPosition,
      'diceValue': diceValue,
      'capturedHorseIds': capturedHorseIds,
    };
  }
}

class LudoGameSnapshot {
  const LudoGameSnapshot({
    required this.matchId,
    required this.players,
    required this.currentTurnIndex,
    required this.phase,
    required this.revision,
    this.diceValue,
    this.lastMove,
    this.winnerPlayerId,
  });

  final String matchId;
  final List<LudoPlayerState> players;
  final int currentTurnIndex;
  final LudoGamePhase phase;
  final int revision;
  final int? diceValue;
  final LudoMoveRecord? lastMove;
  final String? winnerPlayerId;

  LudoPlayerState get currentPlayer => players[currentTurnIndex];

  Iterable<HorseState> get allHorses sync* {
    for (final player in players) {
      yield* player.horses;
    }
  }

  HorseState? horseById(String id) {
    for (final horse in allHorses) {
      if (horse.id == id) return horse;
    }
    return null;
  }

  LudoGameSnapshot copyWith({
    List<LudoPlayerState>? players,
    int? currentTurnIndex,
    LudoGamePhase? phase,
    int? revision,
    int? diceValue,
    LudoMoveRecord? lastMove,
    String? winnerPlayerId,
    bool clearLastMove = false,
  }) {
    return LudoGameSnapshot(
      matchId: matchId,
      players: players ?? this.players,
      currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
      phase: phase ?? this.phase,
      revision: revision ?? this.revision,
      diceValue: diceValue ?? this.diceValue,
      lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
      winnerPlayerId: winnerPlayerId ?? this.winnerPlayerId,
    );
  }

  factory LudoGameSnapshot.fromJson(Map<String, dynamic> json) {
    return LudoGameSnapshot(
      matchId: json['matchId'] as String,
      players: (json['players'] as List<dynamic>)
          .map((player) => LudoPlayerState.fromJson(player as Map<String, dynamic>))
          .toList(),
      currentTurnIndex: json['currentTurnIndex'] as int,
      phase: LudoGamePhase.values.byName(json['phase'] as String),
      revision: json['revision'] as int,
      diceValue: json['diceValue'] as int?,
      lastMove: json['lastMove'] == null
          ? null
          : LudoMoveRecord.fromJson(json['lastMove'] as Map<String, dynamic>),
      winnerPlayerId: json['winnerPlayerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'players': players.map((player) => player.toJson()).toList(),
      'currentTurnIndex': currentTurnIndex,
      'phase': phase.name,
      'revision': revision,
      'diceValue': diceValue,
      'lastMove': lastMove?.toJson(),
      'winnerPlayerId': winnerPlayerId,
    };
  }
}
