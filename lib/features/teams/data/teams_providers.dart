import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/team.dart';
import 'teams_repository.dart';

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  final repo = TeamsRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final teamsStreamProvider = StreamProvider<List<Team>>((ref) {
  return ref.watch(teamsRepositoryProvider).watchAll();
});

final teamsForEventProvider = Provider.family<List<Team>, String>((ref, eventId) {
  final repo = ref.watch(teamsRepositoryProvider);
  return repo.forEvent(eventId);
});

final teamByIdProvider = Provider.family<Team?, String>((ref, id) {
  final repo = ref.watch(teamsRepositoryProvider);
  return repo.byId(id);
});
