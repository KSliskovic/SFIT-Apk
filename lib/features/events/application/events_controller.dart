import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumfit/core/failure.dart';
import 'package:sumfit/core/result.dart';
import '../data/events_providers.dart';
import '../data/events_repository.dart';
import '../domain/event.dart';

class EventsController extends AutoDisposeAsyncNotifier<void> {
  late EventsRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(eventsRepositoryProvider);
  }

  Future<Result<void>> upsert(EventItem e) async {
    state = const AsyncLoading();
    try {
      await _repo.upsert(e);
      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      final f = mapError(e, st);
      state = AsyncError(f, st);
      return Error(f);
    }
  }

  Future<Result<void>> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.delete(id);
      state = const AsyncData(null);
      return const Success(null);
    } catch (e, st) {
      final f = mapError(e, st);
      state = AsyncError(f, st);
      return Error(f);
    }
  }
}

final eventsControllerProvider =
    AutoDisposeAsyncNotifierProvider<EventsController, void>(() => EventsController());
