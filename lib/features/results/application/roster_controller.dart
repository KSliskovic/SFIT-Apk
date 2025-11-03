import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumfit/features/results/data/results_providers.dart';
import '../data/results_repository.dart';

final rosterControllerProvider =
StateNotifierProvider<RosterController, AsyncValue<void>>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  return RosterController(repo);
});

class RosterController extends StateNotifier<AsyncValue<void>> {
  RosterController(this._repo) : super(const AsyncData(null));
  final ResultsRepository _repo;

  Future<void> addTeam({required String name, required String discipline}) async {
    state = const AsyncLoading();
    try {
      await _repo.addTeam(name, discipline);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> addPlayer({required String name, required String discipline}) async {
    state = const AsyncLoading();
    try {
      await _repo.addPlayer(name, discipline);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
