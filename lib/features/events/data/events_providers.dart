import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'events_repository.dart';
import '../domain/event.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) => EventsRepository());

final eventsStreamProvider = StreamProvider<List<EventItem>>((ref) {
  final repo = ref.watch(eventsRepositoryProvider);
  return repo.watchAll();
});

final eventsActionsProvider = Provider<EventsActions>((ref) {
  final repo = ref.watch(eventsRepositoryProvider);
  return EventsActions(repo);
});

class EventsActions {
  final EventsRepository repo;
  EventsActions(this.repo);

  Future<void> deleteEvent(String id) => repo.delete(id);
  Future<void> upsert(EventItem e) => repo.upsert(e);
}
