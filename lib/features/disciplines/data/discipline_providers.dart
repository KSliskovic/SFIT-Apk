import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/discipline.dart';
import 'discipline_repository.dart';

final disciplineRepositoryProvider =
    Provider<DisciplineRepository>((ref) => DisciplineRepository());

final disciplinesStreamProvider = StreamProvider<List<Discipline>>((ref) {
  final repo = ref.watch(disciplineRepositoryProvider);
  // seediraj defaultne ako je prazno (asinkrono, ne blokira stream)
  return repo.watchAll();
});

final teamDisciplinesProvider = Provider<List<Discipline>>((ref) {
  final all = ref.watch(disciplinesStreamProvider).asData?.value ?? const <Discipline>[];
  return all.where((d) => d.isTeam).toList()..sort((a,b)=>a.name.compareTo(b.name));
});

final individualDisciplinesProvider = Provider<List<Discipline>>((ref) {
  final all = ref.watch(disciplinesStreamProvider).asData?.value ?? const <Discipline>[];
  return all.where((d) => !d.isTeam).toList()..sort((a,b)=>a.name.compareTo(b.name));
});
