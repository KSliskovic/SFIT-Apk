import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumfit/features/results/data/results_providers.dart';
import '../data/results_repository.dart';

final resultsControllerProvider =
StateNotifierProvider<ResultsController, AsyncValue<void>>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  return ResultsController(repo);
});

class ResultsController extends StateNotifier<AsyncValue<void>> {
  ResultsController(this._repo) : super(const AsyncData(null));
  final ResultsRepository _repo;

  Future<void> addTeamMatch({
    required String discipline,
    required String teamAId,
    required String teamBId,
    required int scoreA,
    required int scoreB,
    required DateTime? date,
    String? eventId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.addTeamMatch(
        discipline: discipline,
        teamAId: teamAId,
        teamBId: teamBId,
        scoreA: scoreA,
        scoreB: scoreB,
        date: date ?? DateTime.now(),
        eventId: eventId,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> addIndividualMatch({
    required String discipline,
    required String playerAId,
    required String playerBId,
    required int scoreA,
    required int scoreB,
    required DateTime? date,
    String? eventId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.addIndividualMatch(
        discipline: discipline,
        playerAId: playerAId,
        playerBId: playerBId,
        scoreA: scoreA,
        scoreB: scoreB,
        date: date ?? DateTime.now(),
        eventId: eventId,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
