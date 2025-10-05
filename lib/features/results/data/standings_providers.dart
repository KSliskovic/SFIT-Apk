import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/results_repository.dart';
import '../data/results_providers.dart';
import '../domain/models.dart';
import 'disciplines.dart';

/// Streamovi mečeva (koriste i Results i Standings ekrani)
final teamMatchesStreamProvider = StreamProvider<List<TeamMatch>>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.watchTeamMatches();
});

final indivMatchesStreamProvider = StreamProvider<List<IndividualMatch>>((ref) {
  final repo = ref.watch(resultsRepositoryProvider);
  return repo.watchIndividualMatches();
});

/// Tablica poretka (TIMSKI)
final teamTableProvider = Provider.family<List<TableRowEntry>, String>((ref, discipline) {
  ref.watch(teamMatchesStreamProvider);
  ref.watch(teamsStreamProvider);

  final repo = ref.read(resultsRepositoryProvider);

  if (discipline == 'Sve') {
    final all = <TableRowEntry>[];
    for (final d in ref.read(allDisciplinesProvider)) {
      all.addAll(repo.teamTable(d));
    }
    // Agregiraj po imenu
    final map = <String, TableRowEntry>{};
    for (final r in all) {
      final prev = map[r.name];
      if (prev == null) {
        map[r.name] = TableRowEntry(
          id: r.id,
          name: r.name,
          played: r.played,
          wins: r.wins,
          draws: r.draws,
          losses: r.losses,
          goalsFor: r.goalsFor,
          goalsAgainst: r.goalsAgainst,
          points: r.points,
        );
      } else {
        map[r.name] = TableRowEntry(
          id: prev.id,
          name: r.name,
          played: prev.played + r.played,
          wins: prev.wins + r.wins,
          draws: prev.draws + r.draws,
          losses: prev.losses + r.losses,
          goalsFor: prev.goalsFor + r.goalsFor,
          goalsAgainst: prev.goalsAgainst + r.goalsAgainst,
          points: prev.points + r.points,
        );
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.points.compareTo(a.points));
    return list;
  } else {
    return repo.teamTable(discipline);
  }
});

/// Tablica poretka (INDIVIDUALNO)
final indivTableProvider = Provider.family<List<TableRowEntry>, String>((ref, discipline) {
  ref.watch(indivMatchesStreamProvider);
  ref.watch(playersStreamProvider);

  final repo = ref.read(resultsRepositoryProvider);

  if (discipline == 'Sve') {
    final all = <TableRowEntry>[];
    for (final d in ref.read(allDisciplinesProvider)) {
      all.addAll(repo.individualTable(d));
    }
    final map = <String, TableRowEntry>{};
    for (final r in all) {
      final prev = map[r.name];
      if (prev == null) {
        map[r.name] = TableRowEntry(
          id: r.id,
          name: r.name,
          played: r.played,
          wins: r.wins,
          draws: r.draws,
          losses: r.losses,
          goalsFor: r.goalsFor,
          goalsAgainst: r.goalsAgainst,
          points: r.points,
        );
      } else {
        map[r.name] = TableRowEntry(
          id: prev.id,
          name: r.name,
          played: prev.played + r.played,
          wins: prev.wins + r.wins,
          draws: prev.draws + r.draws,
          losses: prev.losses + r.losses,
          goalsFor: prev.goalsFor + r.goalsFor,
          goalsAgainst: prev.goalsAgainst + r.goalsAgainst,
          points: prev.points + r.points,
        );
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.points.compareTo(a.points));
    return list;
  } else {
    return repo.individualTable(discipline);
  }
});
