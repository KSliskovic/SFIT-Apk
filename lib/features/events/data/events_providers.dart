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
// Vrati 1 event po id-u, na temelju eventsStreamProvider-a.
final eventByIdProvider = Provider.family<EventItem?, String>((ref, String id) {
  final listAsync = ref.watch(eventsStreamProvider);
  return listAsync.maybeWhen(
    data: (items) {
      EventItem? found;
      for (final e in items) {
        if (e.id == id) { found = e; break; }
      }
      return found;
    },
    orElse: () => null,
  );
});

class EventsActions {
  final EventsRepository repo;
  EventsActions(this.repo);

  Future<void> deleteEvent(String id) => repo.remove(id);
  Future<void> upsert(EventItem e) => repo.upsert(e);
}
