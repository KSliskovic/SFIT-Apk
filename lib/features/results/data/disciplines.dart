import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../events/data/events_providers.dart';
import '../data/results_providers.dart';
import '../data/results_repository.dart';
import '../domain/models.dart';

/// Ako nigdje nema zapisa, ponudimo ove defaulte
const kDefaultDisciplines = <String>[
  'Nogomet',
  'Košarka',
  'Rukomet',
  'Tenis',
  'Odbojka',
];

/// Centralni izvor istine za discipline:
/// unija (set) disciplina iz TIMOVA, IGRAČA i EVENTA.
/// *Ne* oslanjamo se na “trenutno odabrani event”.
final allDisciplinesProvider = Provider<List<String>>((ref) {
  final teams = ref.watch(teamsStreamProvider).value ?? const <Team>[];
  final players = ref.watch(playersStreamProvider).value ?? const <Player>[];
  final events = ref.watch(eventsStreamProvider).value ?? const <dynamic>[];

  final set = <String>{};

  for (final t in teams) {
    final d = t.discipline.trim();
    if (d.isNotEmpty) set.add(d);
  }
  for (final p in players) {
    final d = p.discipline.trim();
    if (d.isNotEmpty) set.add(d);
  }
  for (final e in events) {
    for (final d in e.disciplines) {
      final v = d.trim();
      if (v.isNotEmpty) set.add(v);
    }
  }

  final out = set.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return out.isEmpty ? kDefaultDisciplines : out;
});

/// Pomoćni provider: lista s "Sve" na vrhu (za filter u ResultsScreen)
final allDisciplinesWithAllProvider = Provider<List<String>>((ref) {
  final base = ref.watch(allDisciplinesProvider);
  return ['Sve', ...base];
});
