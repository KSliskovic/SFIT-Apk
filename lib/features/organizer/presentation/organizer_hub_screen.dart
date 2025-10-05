import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../disciplines/data/discipline_providers.dart';
import '../../results/data/results_providers.dart';
import '../../results/data/results_repository.dart';
import '../../results/domain/models.dart';

class OrganizerHubScreen extends ConsumerStatefulWidget {
  const OrganizerHubScreen({super.key});

  @override
  ConsumerState<OrganizerHubScreen> createState() => _OrganizerHubScreenState();
}

class _OrganizerHubScreenState extends ConsumerState<OrganizerHubScreen> with TickerProviderStateMixin {
  late TabController _tab;
  String? _filterDiscipline; // null => sve

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(resultsRepositoryProvider);

    final teamDisc = ref.watch(teamDisciplinesProvider);
    final indivDisc = ref.watch(individualDisciplinesProvider);
    final allDisc = {
      ...teamDisc.map((d) => d.name),
      ...indivDisc.map((d) => d.name),
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Hub'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Svi članovi'),
            Tab(text: 'Timovi'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: DropdownButtonFormField<String?>(
              value: _filterDiscipline,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem(value: null, child: Text('Sve discipline')),
                ...allDisc.map((n) => DropdownMenuItem(value: n, child: Text(n))),
              ],
              onChanged: (v) => setState(() => _filterDiscipline = v),
              decoration: const InputDecoration(
                labelText: 'Filter po disciplini',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _MembersTab(filterDiscipline: _filterDiscipline, repo: repo),
                _TeamsTab(filterDiscipline: _filterDiscipline, repo: repo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final String? filterDiscipline;
  final ResultsRepository repo;
  const _MembersTab({required this.filterDiscipline, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersStreamProvider);
    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (players) {
        final list = players.where((p) {
          if (filterDiscipline == null) return true;
          return p.discipline == filterDiscipline;
        }).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (list.isEmpty) {
          return const Center(child: Text('Nema članova za odabrani filter.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (c, i) {
            final p = list[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(p.name),
                subtitle: Text(p.discipline),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      final newName = await _promptText(c, 'Uredi igrača', 'Ime i prezime', initial: p.name);
                      if (newName != null && newName.trim().isNotEmpty) {
                        repo.renamePlayer(p.id, newName.trim());
                      }
                    } else if (v == 'delete') {
                      final ok = await _confirm(c, 'Obrisati igrača "${p.name}"?');
                      if (ok == true) repo.deletePlayer(p.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Uredi')),
                    PopupMenuItem(value: 'delete', child: Text('Obriši')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TeamsTab extends ConsumerWidget {
  final String? filterDiscipline;
  final ResultsRepository repo;
  const _TeamsTab({required this.filterDiscipline, required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    return teamsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (teams) {
        final list = teams.where((t) {
          if (filterDiscipline == null) return true;
          return t.discipline == filterDiscipline;
        }).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        if (list.isEmpty) {
          return const Center(child: Text('Nema timova za odabrani filter.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (c, i) {
            final t = list[i];
            return Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.groups)),
                title: Text(t.name),
                subtitle: Text(t.discipline),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      final newName = await _promptText(c, 'Uredi tim', 'Naziv tima', initial: t.name);
                      if (newName != null && newName.trim().isNotEmpty) {
                        repo.renameTeam(t.id, newName.trim());
                      }
                    } else if (v == 'delete') {
                      final ok = await _confirm(c, 'Obrisati tim "${t.name}"?');
                      if (ok == true) repo.deleteTeam(t.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Uredi')),
                    PopupMenuItem(value: 'delete', child: Text('Obriši')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Future<String?> _promptText(BuildContext context, String title, String label, {String? initial}) async {
  final ctrl = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(d).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.of(d).pop(ctrl.text), child: const Text('Spremi')),
      ],
    ),
  );
}

Future<bool?> _confirm(BuildContext context, String msg) {
  return showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('Potvrda'),
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('Ne')),
        FilledButton(onPressed: () => Navigator.of(d).pop(true), child: const Text('Da')),
      ],
    ),
  );
}
