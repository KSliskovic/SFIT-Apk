import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/team_result_entry.dart';
import 'team_results_repository.dart';

final teamResultsRepositoryProvider = Provider<TeamResultsRepository>((ref) {
  final repo = TeamResultsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final teamResultsForEventDisciplineProvider =
    Provider.family<List<TeamResultEntry>, ({String eventId, String discipline})>((ref, key) {
  final repo = ref.watch(teamResultsRepositoryProvider);
  return repo.forEventDiscipline(key.eventId, key.discipline);
});
