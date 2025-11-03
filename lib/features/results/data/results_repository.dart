// lib/features/results/data/results_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models.dart';

class ResultsRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _teamsCol => _db.collection('teams');
  CollectionReference<Map<String, dynamic>> get _playersCol => _db.collection('players');
  CollectionReference<Map<String, dynamic>> get _teamMatchesCol => _db.collection('matches_team');
  CollectionReference<Map<String, dynamic>> get _individualMatchesCol => _db.collection('matches_individual');

  // --- Streams
  Stream<List<Team>> watchTeams() => _teamsCol.orderBy('name').snapshots().map(
        (s) => s.docs.map((d) => Team.fromJson({...d.data(), 'id': d.id})).toList(),
  );

  Stream<List<Player>> watchPlayers() => _playersCol.orderBy('name').snapshots().map(
        (s) => s.docs.map((d) => Player.fromJson({...d.data(), 'id': d.id})).toList(),
  );

  Stream<List<TeamMatch>> watchTeamMatches() => _teamMatchesCol.orderBy('date', descending: true).snapshots().map(
        (s) => s.docs.map((d) => TeamMatch.fromJson({...d.data(), 'id': d.id})).toList(),
  );

  Stream<List<IndividualMatch>> watchIndividualMatches() =>
      _individualMatchesCol.orderBy('date', descending: true).snapshots().map(
            (s) => s.docs.map((d) => IndividualMatch.fromJson({...d.data(), 'id': d.id})).toList(),
      );

  // --- Mutacije: timovi/igrači
  Future<void> addTeam(String name, String discipline) async {
    await _teamsCol.add({'name': name, 'discipline': discipline});
  }

  Future<void> addPlayer(String name, String discipline) async {
    await _playersCol.add({'name': name, 'discipline': discipline});
  }

  Future<void> renameTeam(String id, String newName) async {
    await _teamsCol.doc(id).update({'name': newName});
  }

  Future<void> renamePlayer(String id, String newName) async {
    await _playersCol.doc(id).update({'name': newName});
  }

  Future<void> deleteTeam(String id) async {
    await _teamsCol.doc(id).delete();
  }

  Future<void> deletePlayer(String id) async {
    await _playersCol.doc(id).delete();
  }

  // --- Rezultati
  Future<void> addTeamMatch({
    required String discipline,
    required String teamAId,
    required String teamBId,
    required int scoreA,
    required int scoreB,
    required DateTime date,
    String? eventId,
  }) async {
    final winner = _winner(scoreA, scoreB);
    await _teamMatchesCol.add({
      'discipline': discipline,
      'teamAId': teamAId,
      'teamBId': teamBId,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'date': Timestamp.fromDate(date),
      'winner': winner,
      if (eventId != null) 'eventId': eventId,
    });
  }

  Future<void> addIndividualMatch({
    required String discipline,
    required String playerAId,
    required String playerBId,
    required int scoreA,
    required int scoreB,
    required DateTime date,
    String? eventId,
  }) async {
    final winner = _winner(scoreA, scoreB);
    await _individualMatchesCol.add({
      'discipline': discipline,
      'playerAId': playerAId,
      'playerBId': playerBId,
      'scoreA': scoreA,
      'scoreB': scoreB,
      'date': Timestamp.fromDate(date),
      'winner': winner,
      if (eventId != null) 'eventId': eventId,
    });
  }

  // --- Tablice (placeholder)
  List<TableRowEntry> teamTable(String discipline, {List<TeamMatch> source = const []}) => const [];
  List<TableRowEntry> individualTable(String discipline, {List<IndividualMatch> source = const []}) => const [];

  int _winner(int a, int b) => a == b ? 0 : (a > b ? 1 : 2);
}
