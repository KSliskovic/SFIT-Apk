import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/results_providers.dart';
import '../data/results_repository.dart';
import '../domain/models.dart';

enum DirectoryFilter { all, teams, players }

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  late final List<String> _allDisciplines;
  String _discipline = 'Sve discipline';
  DirectoryFilter _filter = DirectoryFilter.all;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _allDisciplines = [
      'Sve discipline',
      ...ResultsRepository.teamDisciplines,
      ...ResultsRepository.individualDisciplines,
    ];
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchDiscipline(String itemDisc) {
    if (_discipline == 'Sve discipline') return true;
    return itemDisc == _discipline;
  }

  bool _matchSearch(String name) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(resultsRepositoryProvider);
    final teamsAsync = ref.watch(teamsStreamProvider);
    final playersAsync = ref.watch(playersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Direktorij • Timovi & Igrači'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Filter red
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _discipline,
                    items: _allDisciplines
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _discipline = v ?? 'Sve discipline'),
                    decoration: const InputDecoration(
                      labelText: 'Disciplina',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<DirectoryFilter>(
                  segments: const [
                    ButtonSegment(value: DirectoryFilter.all, label: Text('Sve')),
                    ButtonSegment(value: DirectoryFilter.teams, label: Text('Timovi')),
                    ButtonSegment(value: DirectoryFilter.players, label: Text('Igrači')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Traži naziv tima ili igrača',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search.clear()),
                      ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: teamsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Greška (timovi): $e')),
                data: (teams) {
                  return playersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Greška (igrači): $e')),
                    data: (players) {
                      // Filtriraj
                      final ftTeams = teams
                          .where((t) => _matchDiscipline(t.discipline) && _matchSearch(t.name))
                          .toList()
                        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                      final ftPlayers = players
                          .where((p) => _matchDiscipline(p.discipline) && _matchSearch(p.name))
                          .toList()
                        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                      final List<_DirRow> rows = [];
                      if (_filter == DirectoryFilter.all || _filter == DirectoryFilter.teams) {
                        rows.addAll(ftTeams.map((t) => _DirRow.team(t)));
                      }
                      if (_filter == DirectoryFilter.all || _filter == DirectoryFilter.players) {
                        rows.addAll(ftPlayers.map((p) => _DirRow.player(p)));
                      }

                      rows.sort((a, b) {
                        if (a.kind != b.kind) return a.kind == _DirKind.team ? -1 : 1;
                        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                      });

                      if (rows.isEmpty) {
                        return const Center(child: Text('Nema rezultata za zadani filter.'));
                      }

                      return ListView.separated(
                        itemBuilder: (_, i) {
                          final r = rows[i];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(r.kind == _DirKind.team ? Icons.groups : Icons.person),
                            ),
                            title: Text(r.name),
                            subtitle: Text(r.discipline),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (r.kind == _DirKind.team) {
                                  if (v == 'edit') {
                                    final res = await _editTeamDialog(context, r, repo);
                                    if (res == true && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Tim ažuriran')),
                                      );
                                    }
                                  } else if (v == 'delete') {
                                    final ok = await _confirmDelete(context,
                                        'Obrisati tim i sve njegove utakmice?');
                                    if (ok == true) {
                                      repo.deleteTeam(r.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Tim obrisan')),
                                        );
                                      }
                                    }
                                  }
                                } else {
                                  if (v == 'edit') {
                                    final res = await _editPlayerDialog(context, r, repo);
                                    if (res == true && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Igrač ažuriran')),
                                      );
                                    }
                                  } else if (v == 'delete') {
                                    final ok = await _confirmDelete(
                                        context, 'Obrisati igrača i sve njegove mečeve?');
                                    if (ok == true) {
                                      repo.deletePlayer(r.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Igrač obrisan')),
                                        );
                                      }
                                    }
                                  }
                                }
                              },
                              itemBuilder: (c) => const [
                                PopupMenuItem(value: 'edit', child: Text('Uredi')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Obriši', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: rows.length,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DirKind { team, player }

class _DirRow {
  final _DirKind kind;
  final String id;
  final String name;
  final String discipline;

  _DirRow._(this.kind, this.id, this.name, this.discipline);

  factory _DirRow.team(Team t) => _DirRow._(_DirKind.team, t.id, t.name, t.discipline);
  factory _DirRow.player(Player p) => _DirRow._(_DirKind.player, p.id, p.name, p.discipline);
}

// ---------- Dijalozi ----------

Future<bool?> _confirmDelete(BuildContext context, String msg) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Potvrda brisanja'),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(false),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(true),
          child: const Text('Obriši'),
        ),
      ],
    ),
  );
}

Future<bool?> _editTeamDialog(BuildContext context, _DirRow r, ResultsRepository repo) {
  final nameCtrl = TextEditingController(text: r.name);
  String disc = ResultsRepository.teamDisciplines.contains(r.discipline)
      ? r.discipline
      : ResultsRepository.teamDisciplines.first;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Uredi tim'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Naziv tima'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: disc,
            items: ResultsRepository.teamDisciplines
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => disc = v ?? disc,
            decoration: const InputDecoration(labelText: 'Disciplina'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(false),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            final n = nameCtrl.text.trim();
            if (n.isEmpty) return;
            repo.updateTeam(r.id, name: n, discipline: disc);
            Navigator.of(dialogCtx, rootNavigator: true).pop(true);
          },
          child: const Text('Spremi'),
        ),
      ],
    ),
  );
}

Future<bool?> _editPlayerDialog(BuildContext context, _DirRow r, ResultsRepository repo) {
  final nameCtrl = TextEditingController(text: r.name);
  String disc = ResultsRepository.individualDisciplines.contains(r.discipline)
      ? r.discipline
      : ResultsRepository.individualDisciplines.first;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Uredi igrača'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Ime i prezime'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: disc,
            items: ResultsRepository.individualDisciplines
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => disc = v ?? disc,
            decoration: const InputDecoration(labelText: 'Disciplina'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(false),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            final n = nameCtrl.text.trim();
            if (n.isEmpty) return;
            repo.updatePlayer(r.id, name: n, discipline: disc);
            Navigator.of(dialogCtx, rootNavigator: true).pop(true);
          },
          child: const Text('Spremi'),
        ),
      ],
    ),
  );
}
