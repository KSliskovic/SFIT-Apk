import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/discipline.dart';
import 'discipline_repository.dart';

/// Stream svih disciplina (sortirano po nameLower)
final disciplinesStreamProvider = StreamProvider<List<Discipline>>((ref) {
  final repo = ref.watch(disciplineRepositoryProvider);
  return repo.streamAll();
});

/// Samo lista imena (ako ti zatreba)
final disciplineNamesProvider = Provider<List<String>>((ref) {
  final av = ref.watch(disciplinesStreamProvider);
  return av.maybeWhen(
    data: (list) => list.map((e) => e.name).toList(),
    orElse: () => const [],
  );
});
