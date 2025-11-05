import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/discipline.dart';
import 'discipline_repository.dart';

final disciplineRepositoryProvider = Provider((_) => DisciplineRepository());

final disciplinesStreamProvider = StreamProvider<List<Discipline>>((ref) {
  return ref.watch(disciplineRepositoryProvider).streamAll();
});

/// Prijelazni helper: vrati isTeam po NAZIVU discipline
final disciplineIsTeamByNameProvider = Provider.family<bool?, String?>((ref, name) {
  final list = ref.watch(disciplinesStreamProvider).value ?? const <Discipline>[];
  if (name == null) return null;
  final found = list.where((d) => d.name.toLowerCase() == name.toLowerCase());
  if (found.isEmpty) return null;
  return found.first.isTeam;
});

/// (Opcionalno) dohvati cijeli objekt discipline po imenu
final disciplineByNameProvider = Provider.family<Discipline?, String?>((ref, name) {
  final list = ref.watch(disciplinesStreamProvider).value ?? const <Discipline>[];
  if (name == null) return null;
  for (final d in list) {
    if (d.name.toLowerCase() == name.toLowerCase()) return d;
  }
  return null;
});
