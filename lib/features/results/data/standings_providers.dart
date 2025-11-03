// lib/features/results/data/standings_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../data/results_providers.dart' as rp;

// Export pravih stream providera (da ih ResultsScreen vidi kroz `standings.*`)
export '../data/results_providers.dart'
    show individualMatchesStreamProvider, teamMatchesStreamProvider;

// Alias za back-compat: standings.indivMatchesStreamProvider
final indivMatchesStreamProvider = rp.individualMatchesStreamProvider;

/// ------------------------------------------------------------------
/// STANDINGS (poredak) provideri
/// Bodovanje: pobjeda 3, neriješeno 1, poraz 0.
/// Zbrajamo: played, wins, draws, losses, goalsFor, goalsAgainst, points.
/// Sort: points desc, wins desc, diff(GF-GA) desc, goalsFor desc, name asc.
/// Imena: mapiraju se iz players/teams streamova (ID → name).
/// ------------------------------------------------------------------

final individualStandingsProvider =
Provider.family<AsyncValue<List<TableRowEntry>>, String?>((ref, discipline) {
  final matchesAV = ref.watch(rp.individualMatchesStreamProvider);
  final playersAV = ref.watch(rp.playersStreamProvider);

  // Kad se promijene mečevi, izračunaj; imena ako su dostupna
  return matchesAV.whenData((matches) {
    final players = playersAV.value ?? const <Player>[];
    final nameOf = {
      for (final p in players) p.id: p.name,
    };

    final map = <String, TableRowEntry>{};

    void ensure(String id) {
      map.putIfAbsent(
        id,
            () => TableRowEntry(
          id: id,
          name: nameOf[id] ?? id, // ako player još nije učitan, fallback je id
          played: 0,
          wins: 0,
          draws: 0,
          losses: 0,
          goalsFor: 0,
          goalsAgainst: 0,
          points: 0,
        ),
      );
    }

    for (final m in matches) {
      if (discipline != null && discipline != 'Sve' && m.discipline != discipline) continue;

      ensure(m.playerAId);
      ensure(m.playerBId);

      final a = map[m.playerAId]!;
      final b = map[m.playerBId]!;

      final aGF = a.goalsFor + m.scoreA;
      final aGA = a.goalsAgainst + m.scoreB;
      final bGF = b.goalsFor + m.scoreB;
      final bGA = b.goalsAgainst + m.scoreA;

      int aW = a.wins, aD = a.draws, aL = a.losses, aP = a.points;
      int bW = b.wins, bD = b.draws, bL = b.losses, bP = b.points;

      if (m.scoreA > m.scoreB) {
        aW++; aP += 3; bL++;
      } else if (m.scoreA < m.scoreB) {
        bW++; bP += 3; aL++;
      } else {
        aD++; bD++; aP++; bP++;
      }

      map[m.playerAId] = TableRowEntry(
        id: a.id,
        name: nameOf[a.id] ?? a.name,
        played: a.played + 1,
        wins: aW,
        draws: aD,
        losses: aL,
        goalsFor: aGF,
        goalsAgainst: aGA,
        points: aP,
      );
      map[m.playerBId] = TableRowEntry(
        id: b.id,
        name: nameOf[b.id] ?? b.name,
        played: b.played + 1,
        wins: bW,
        draws: bD,
        losses: bL,
        goalsFor: bGF,
        goalsAgainst: bGA,
        points: bP,
      );
    }

    final list = map.values.toList()
      ..sort((a, b) {
        final pts = b.points.compareTo(a.points);
        if (pts != 0) return pts;
        final wins = b.wins.compareTo(a.wins);
        if (wins != 0) return wins;
        final diff = (b.goalsFor - b.goalsAgainst)
            .compareTo(a.goalsFor - a.goalsAgainst);
        if (diff != 0) return diff;
        final gf = b.goalsFor.compareTo(a.goalsFor);
        if (gf != 0) return gf;
        return a.name.compareTo(b.name);
      });

    return list;
  });
});

final teamStandingsProvider =
Provider.family<AsyncValue<List<TableRowEntry>>, String?>((ref, discipline) {
  final matchesAV = ref.watch(rp.teamMatchesStreamProvider);
  final teamsAV = ref.watch(rp.teamsStreamProvider);

  return matchesAV.whenData((matches) {
    final teams = teamsAV.value ?? const <Team>[];
    final nameOf = {
      for (final t in teams) t.id: t.name,
    };

    final map = <String, TableRowEntry>{};

    void ensure(String id) {
      map.putIfAbsent(
        id,
            () => TableRowEntry(
          id: id,
          name: nameOf[id] ?? id,
          played: 0,
          wins: 0,
          draws: 0,
          losses: 0,
          goalsFor: 0,
          goalsAgainst: 0,
          points: 0,
        ),
      );
    }

    for (final m in matches) {
      if (discipline != null && discipline != 'Sve' && m.discipline != discipline) continue;

      ensure(m.teamAId);
      ensure(m.teamBId);

      final a = map[m.teamAId]!;
      final b = map[m.teamBId]!;

      final aGF = a.goalsFor + m.scoreA;
      final aGA = a.goalsAgainst + m.scoreB;
      final bGF = b.goalsFor + m.scoreB;
      final bGA = b.goalsAgainst + m.scoreA;

      int aW = a.wins, aD = a.draws, aL = a.losses, aP = a.points;
      int bW = b.wins, bD = b.draws, bL = b.losses, bP = b.points;

      if (m.scoreA > m.scoreB) {
        aW++; aP += 3; bL++;
      } else if (m.scoreA < m.scoreB) {
        bW++; bP += 3; aL++;
      } else {
        aD++; bD++; aP++; bP++;
      }

      map[m.teamAId] = TableRowEntry(
        id: a.id,
        name: nameOf[a.id] ?? a.name,
        played: a.played + 1,
        wins: aW,
        draws: aD,
        losses: aL,
        goalsFor: aGF,
        goalsAgainst: aGA,
        points: aP,
      );
      map[m.teamBId] = TableRowEntry(
        id: b.id,
        name: nameOf[b.id] ?? b.name,
        played: b.played + 1,
        wins: bW,
        draws: bD,
        losses: bL,
        goalsFor: bGF,
        goalsAgainst: bGA,
        points: bP,
      );
    }

    final list = map.values.toList()
      ..sort((a, b) {
        final pts = b.points.compareTo(a.points);
        if (pts != 0) return pts;
        final wins = b.wins.compareTo(a.wins);
        if (wins != 0) return wins;
        final diff = (b.goalsFor - b.goalsAgainst)
            .compareTo(a.goalsFor - a.goalsAgainst);
        if (diff != 0) return diff;
        final gf = b.goalsFor.compareTo(a.goalsFor);
        if (gf != 0) return gf;
        return a.name.compareTo(b.name);
      });

    return list;
  });
});
