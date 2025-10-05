import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/results_repository.dart';
import '../data/results_providers.dart';
import 'package:sumfit/core/failure.dart';
import 'package:sumfit/core/result.dart';

class RosterController extends AutoDisposeAsyncNotifier<void> {
  late ResultsRepository _repo;
  @override
  Future<void> build() async { _repo = ref.read(resultsRepositoryProvider); }

  Future<Result<void>> addTeam({required String name, required String discipline}) async {
    state = const AsyncLoading();
    try { _repo.addTeam(name, discipline); state = const AsyncData(null); return const Success(null); }
    catch (e, st) { final f = Failure(e.toString(), cause:e, stackTrace:st); state = AsyncError(f, st); return Error(f); }
  }

  Future<Result<void>> addPlayer({required String name, required String discipline}) async {
    state = const AsyncLoading();
    try { _repo.addPlayer(name, discipline); state = const AsyncData(null); return const Success(null); }
    catch (e, st) { final f = Failure(e.toString(), cause:e, stackTrace:st); state = AsyncError(f, st); return Error(f); }
  }
}

final rosterControllerProvider =
  AutoDisposeAsyncNotifierProvider<RosterController, void>(() => RosterController());
