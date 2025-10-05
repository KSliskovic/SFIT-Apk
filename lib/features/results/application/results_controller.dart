import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumfit/core/failure.dart';
import 'package:sumfit/core/result.dart';
import '../data/results_providers.dart';
import '../data/results_repository.dart';

class ResultsController extends AutoDisposeAsyncNotifier<void> {
  late ResultsRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(resultsRepositoryProvider);
  }

  Future<Result<void>> addTeamMatch({
    required String discipline,
    required String teamAId,
    required String teamBId,
    required int scoreA,
    required int scoreB,
    DateTime? date,
  }) async {
    state = const AsyncLoading();
    try {
      _repo.addTeamMatch(
        discipline: discipline,
        teamAId: teamAId,
        teamBId: teamBId,
        scoreA: scoreA,
        scoreB: scoreB,
        date: date,
      );
      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      final f = mapError(e, st);
      state = AsyncError(f, st);
      return Error(f);
    }
  }

  Future<Result<void>> addIndividualMatch({
    required String discipline,
    required String playerAId,
    required String playerBId,
    required int scoreA,
    required int scoreB,
    DateTime? date,
  }) async {
    state = const AsyncLoading();
    try {
      _repo.addIndividualMatch(
        discipline: discipline,
        playerAId: playerAId,
        playerBId: playerBId,
        scoreA: scoreA,
        scoreB: scoreB,
        date: date,
      );
      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      final f = mapError(e, st);
      state = AsyncError(f, st);
      return Error(f);
    }
  }
}

final resultsControllerProvider =
    AutoDisposeAsyncNotifierProvider<ResultsController, void>(() {
  return ResultsController();
});
