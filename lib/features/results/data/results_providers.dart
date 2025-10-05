import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'results_repository.dart';
import '../domain/models.dart';

/// Glavni repo
final resultsRepositoryProvider = Provider<ResultsRepository>((ref) {
  return ResultsRepository();
});

/// Streamovi (osnovni)
final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.watchTeams();
});

final playersStreamProvider = StreamProvider<List<Player>>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.watchPlayers();
});

final teamMatchesStreamProvider = StreamProvider<List<TeamMatch>>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.watchTeamMatches();
});

final individualMatchesStreamProvider = StreamProvider<List<IndividualMatch>>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.watchIndividualMatches();
});

/// Tablice (poredak)
final teamTableProvider = Provider.family<List<TableRowEntry>, String>((ref, discipline) {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.teamTable(discipline);
});

final individualTableProvider = Provider.family<List<TableRowEntry>, String>((ref, discipline) {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.individualTable(discipline);
});

/// ========= NEW: filtrirani provideri koji NIKAD ne ostavljaju UI u loading petlji ==========
/// Ako je [discipline] null ili "Svi", vraća se puni popis bez filtriranja.
final playersFilteredProvider =
    Provider.family<AsyncValue<List<Player>>, String?>((ref, discipline) {
  final base = ref.watch(playersStreamProvider);
  return base.whenData((list) {
    if (discipline == null || discipline == 'Svi') return list;
    return list.where((p) => p.discipline == discipline).toList();
  });
});

final teamsFilteredProvider =
    Provider.family<AsyncValue<List<Team>>, String?>((ref, discipline) {
  final base = ref.watch(teamsStreamProvider);
  return base.whenData((list) {
    if (discipline == null || discipline == 'Svi') return list;
    return list.where((t) => t.discipline == discipline).toList();
  });
});
