// lib/features/results/domain/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String discipline;

  const Team({required this.id, required this.name, required this.discipline});

  Team copyWith({String? id, String? name, String? discipline}) => Team(
    id: id ?? this.id,
    name: name ?? this.name,
    discipline: discipline ?? this.discipline,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'discipline': discipline,
  };

  static Team fromJson(Map<String, dynamic> json) => Team(
    id: json['id'] as String,
    name: json['name'] as String,
    discipline: json['discipline'] as String,
  );
}

class Player {
  final String id;
  final String name;
  final String discipline;

  const Player({required this.id, required this.name, required this.discipline});

  Player copyWith({String? id, String? name, String? discipline}) => Player(
    id: id ?? this.id,
    name: name ?? this.name,
    discipline: discipline ?? this.discipline,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'discipline': discipline,
  };

  static Player fromJson(Map<String, dynamic> json) => Player(
    id: json['id'] as String,
    name: json['name'] as String,
    discipline: json['discipline'] as String,
  );
}

class TeamMatch {
  final String id;
  final String discipline;
  final String teamAId;
  final String teamBId;
  final int scoreA;
  final int scoreB;
  final DateTime date; // Firestore Timestamp → DateTime
  /// 0 = neriješeno, 1 = pobjeda A, 2 = pobjeda B
  final int winner;
  /// veza na event
  final String? eventId;

  const TeamMatch({
    required this.id,
    required this.discipline,
    required this.teamAId,
    required this.teamBId,
    required this.scoreA,
    required this.scoreB,
    required this.date,
    required this.winner,
    this.eventId,
  });

  Map<String, dynamic> toJson() => {
    'discipline': discipline,
    'teamAId': teamAId,
    'teamBId': teamBId,
    'scoreA': scoreA,
    'scoreB': scoreB,
    'date': Timestamp.fromDate(date),
    'winner': winner,
    if (eventId != null) 'eventId': eventId,
  };

  static TeamMatch fromJson(Map<String, dynamic> json) => TeamMatch(
    id: json['id'] as String,
    discipline: json['discipline'] as String,
    teamAId: json['teamAId'] as String,
    teamBId: json['teamBId'] as String,
    scoreA: (json['scoreA'] as num).toInt(),
    scoreB: (json['scoreB'] as num).toInt(),
    date: _asDateTime(json['date']),
    winner: (json['winner'] as num).toInt(),
    eventId: json['eventId'] as String?,
  );

  static DateTime _asDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return v as DateTime;
  }
}

class IndividualMatch {
  final String id;
  final String discipline;
  final String playerAId;
  final String playerBId;
  final int scoreA;
  final int scoreB;
  final DateTime date;
  /// 0 = neriješeno, 1 = pobjeda A, 2 = pobjeda B
  final int winner;
  /// veza na event
  final String? eventId;

  const IndividualMatch({
    required this.id,
    required this.discipline,
    required this.playerAId,
    required this.playerBId,
    required this.scoreA,
    required this.scoreB,
    required this.date,
    required this.winner,
    this.eventId,
  });

  Map<String, dynamic> toJson() => {
    'discipline': discipline,
    'playerAId': playerAId,
    'playerBId': playerBId,
    'scoreA': scoreA,
    'scoreB': scoreB,
    'date': Timestamp.fromDate(date),
    'winner': winner,
    if (eventId != null) 'eventId': eventId,
  };

  static IndividualMatch fromJson(Map<String, dynamic> json) => IndividualMatch(
    id: json['id'] as String,
    discipline: json['discipline'] as String,
    playerAId: json['playerAId'] as String,
    playerBId: json['playerBId'] as String,
    scoreA: (json['scoreA'] as num).toInt(),
    scoreB: (json['scoreB'] as num).toInt(),
    date: _asDateTime(json['date']),
    winner: (json['winner'] as num).toInt(),
    eventId: json['eventId'] as String?,
  );

  static DateTime _asDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.parse(v);
    return v as DateTime;
  }
}

class TableRowEntry {
  final String id;
  final String name;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  const TableRowEntry({
    required this.id,
    required this.name,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.points,
  });

  int get diff => goalsFor - goalsAgainst;
}
