import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class ResultsRepository {
  static const _storeKey = 'sumfit_results_repo_v1';

  final List<Team> _teams = [];
  final List<Player> _players = [];
  final List<TeamMatch> _teamMatches = [];
  final List<IndividualMatch> _individualMatches = [];

  final _teamsCtrl = StreamController<List<Team>>.broadcast();
  final _playersCtrl = StreamController<List<Player>>.broadcast();
  final _teamMatchesCtrl = StreamController<List<TeamMatch>>.broadcast();
  final _individualMatchesCtrl = StreamController<List<IndividualMatch>>.broadcast();

  ResultsRepository() {
    _restore();
  }

  // Streams
  Stream<List<Team>> watchTeams() => _teamsCtrl.stream;
  Stream<List<Player>> watchPlayers() => _playersCtrl.stream;
  Stream<List<TeamMatch>> watchTeamMatches() => _teamMatchesCtrl.stream;
  Stream<List<IndividualMatch>> watchIndividualMatches() => _individualMatchesCtrl.stream;

  // Add
  void addTeam(String name, String discipline) {
    _teams.add(Team(id: _newId('team'), name: name, discipline: discipline));
    _emitTeams(); _persist();
  }

  void addPlayer(String name, String discipline) {
    _players.add(Player(id: _newId('player'), name: name, discipline: discipline));
    _emitPlayers(); _persist();
  }

  void addTeamMatch({
    required String discipline,
    required String teamAId,
    required String teamBId,
    required int scoreA,
    required int scoreB,
    DateTime? date,
  }) {
    final m = TeamMatch(
      id: _newId('tmatch'),
      discipline: discipline,
      teamAId: teamAId,
      teamBId: teamBId,
      scoreA: scoreA,
      scoreB: scoreB,
      date: date ?? DateTime.now(),
      winner: scoreA == scoreB ? 0 : (scoreA > scoreB ? 1 : 2),
    );
    _teamMatches.add(m);
    _emitTeamMatches(); _persist();
  }

  void addIndividualMatch({
    required String discipline,
    required String playerAId,
    required String playerBId,
    required int scoreA,
    required int scoreB,
    DateTime? date,
  }) {
    final m = IndividualMatch(
      id: _newId('imatch'),
      discipline: discipline,
      playerAId: playerAId,
      playerBId: playerBId,
      scoreA: scoreA,
      scoreB: scoreB,
      date: date ?? DateTime.now(),
      winner: scoreA == scoreB ? 0 : (scoreA > scoreB ? 1 : 2),
    );
    _individualMatches.add(m);
    _emitIndividualMatches(); _persist();
  }

  // Edit / delete
  void renameTeam(String teamId, String newName) {
    final i = _teams.indexWhere((t) => t.id == teamId);
    if (i < 0) return;
    _teams[i] = _teams[i].copyWith(name: newName);
    _emitTeams(); _persist();
  }

  void deleteTeam(String teamId) {
    _teams.removeWhere((t) => t.id == teamId);
    _teamMatches.removeWhere((m) => m.teamAId == teamId || m.teamBId == teamId);
    _emitTeams(); _emitTeamMatches(); _persist();
  }

  void renamePlayer(String playerId, String newName) {
    final i = _players.indexWhere((p) => p.id == playerId);
    if (i < 0) return;
    _players[i] = _players[i].copyWith(name: newName);
    _emitPlayers(); _persist();
  }

  void deletePlayer(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
    _individualMatches.removeWhere((m) => m.playerAId == playerId || m.playerBId == playerId);
    _emitPlayers(); _emitIndividualMatches(); _persist();
  }

  // Tables
  List<TableRowEntry> teamTable(String discipline) {
    final teams = _teams.where((t) => t.discipline == discipline).toList();

    final rows = <String, _RowAcc>{};
    for (final t in teams) {
      rows[t.id] = _RowAcc(id: t.id, name: t.name);
    }
    for (final m in _teamMatches.where((m) => m.discipline == discipline)) {
      final a = rows[m.teamAId];
      final b = rows[m.teamBId];
      if (a == null || b == null) continue;

      a.played++; b.played++;
      a.goalsFor += m.scoreA; a.goalsAgainst += m.scoreB;
      b.goalsFor += m.scoreB; b.goalsAgainst += m.scoreA;

      if (m.winner == 0) {
        a.draws++; b.draws++; a.points += 1; b.points += 1;
      } else if (m.winner == 1) {
        a.wins++; b.losses++; a.points += 3;
      } else {
        b.wins++; a.losses++; b.points += 3;
      }
    }

    final out = <TableRowEntry>[];
    for (final id in rows.keys) {
      final r = rows[id]!;
      out.add(TableRowEntry(
        id: id,
        name: r.name,
        played: r.played,
        wins: r.wins,
        draws: r.draws,
        losses: r.losses,
        goalsFor: r.goalsFor,
        goalsAgainst: r.goalsAgainst,
        points: r.points,
      ));
    }
    out.sort(_tableSort);
    return out;
  }

  List<TableRowEntry> individualTable(String discipline) {
    final players = _players.where((p) => p.discipline == discipline).toList();

    final rows = <String, _RowAcc>{};
    for (final p in players) {
      rows[p.id] = _RowAcc(id: p.id, name: p.name);
    }
    for (final m in _individualMatches.where((m) => m.discipline == discipline)) {
      final a = rows[m.playerAId];
      final b = rows[m.playerBId];
      if (a == null || b == null) continue;

      a.played++; b.played++;
      a.goalsFor += m.scoreA; a.goalsAgainst += m.scoreB;
      b.goalsFor += m.scoreB; b.goalsAgainst += m.scoreA;

      if (m.winner == 0) {
        a.draws++; b.draws++; a.points += 1; b.points += 1;
      } else if (m.winner == 1) {
        a.wins++; b.losses++; a.points += 3;
      } else {
        b.wins++; a.losses++; b.points += 3;
      }
    }

    final out = <TableRowEntry>[];
    for (final id in rows.keys) {
      final r = rows[id]!;
      out.add(TableRowEntry(
        id: id,
        name: r.name,
        played: r.played,
        wins: r.wins,
        draws: r.draws,
        losses: r.losses,
        goalsFor: r.goalsFor,
        goalsAgainst: r.goalsAgainst,
        points: r.points,
      ));
    }
    out.sort(_tableSort);
    return out;
  }

  int _tableSort(TableRowEntry a, TableRowEntry b) {
    final byPts = b.points.compareTo(a.points);
    if (byPts != 0) return byPts;
    final byDiff = b.diff.compareTo(a.diff);
    if (byDiff != 0) return byDiff;
    return b.goalsFor.compareTo(a.goalsFor);
  }

  // Helpers/persistence
  String _newId(String prefix) => '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  void _emitTeams() => _teamsCtrl.add(List.unmodifiable(_teams));
  void _emitPlayers() => _playersCtrl.add(List.unmodifiable(_players));
  void _emitTeamMatches() => _teamMatchesCtrl.add(List.unmodifiable(_teamMatches));
  void _emitIndividualMatches() => _individualMatchesCtrl.add(List.unmodifiable(_individualMatches));

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'teams': _teams.map((e) => e.toJson()).toList(),
      'players': _players.map((e) => e.toJson()).toList(),
      'teamMatches': _teamMatches.map((e) => e.toJson()).toList(),
      'individualMatches': _individualMatches.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_storeKey, jsonEncode(data));
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw == null) {
      _emitTeams(); _emitPlayers(); _emitTeamMatches(); _emitIndividualMatches();
      return;
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _teams
      ..clear()
      ..addAll(((map['teams'] as List?) ?? const [])
          .map((e) => Team.fromJson(Map<String, dynamic>.from(e))));
    _players
      ..clear()
      ..addAll(((map['players'] as List?) ?? const [])
          .map((e) => Player.fromJson(Map<String, dynamic>.from(e))));
    _teamMatches
      ..clear()
      ..addAll(((map['teamMatches'] as List?) ?? const [])
          .map((e) => TeamMatch.fromJson(Map<String, dynamic>.from(e))));
    _individualMatches
      ..clear()
      ..addAll(((map['individualMatches'] as List?) ?? const [])
          .map((e) => IndividualMatch.fromJson(Map<String, dynamic>.from(e))));
    _emitTeams(); _emitPlayers(); _emitTeamMatches(); _emitIndividualMatches();
  }
}

class _RowAcc {
  final String id;
  final String name;
  int played = 0, wins = 0, draws = 0, losses = 0;
  int goalsFor = 0, goalsAgainst = 0, points = 0;
  _RowAcc({required this.id, required this.name});
}
