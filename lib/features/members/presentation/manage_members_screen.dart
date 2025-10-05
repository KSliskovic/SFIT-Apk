import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/members_providers.dart';
import '../../results/domain/models.dart';

class ManageMembersScreen extends ConsumerStatefulWidget {
  const ManageMembersScreen({super.key});

  @override
  ConsumerState<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends ConsumerState<ManageMembersScreen> {
  String _disciplineFilter = 'Sve';
  int _tabIndex = 0; // 0 = Timovi, 1 = Igrači

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final playersAsync = ref.watch(playersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Članovi i timovi'),
        actions: [
          // Dropdown za filtriranje po disciplini (skupljamo iz timova + igrača)
          teamsAsync.when(
            data: (teams) {
              final players = playersAsync.maybeWhen(data: (p) => p, orElse: () => const <Player>[]);
              final allDisciplines = <String>{
                ...teams.map((t) => t.discipline),
                ...players.map((p) => p.discipline),
              }..removeWhere((e) => (e).trim().isEmpty);
              final items = ['Sve', ...allDisciplines.toList()..sort()];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _disciplineFilter,
                    items: items.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setState(() => _disciplineFilter = v ?? 'Sve'),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: TabBar(
          onTap: (i) => setState(() => _tabIndex = i),
          tabs: const [
            Tab(text: 'Timovi'),
            Tab(text: 'Igrači'),
          ],
          controller: TabController(length: 2, vsync: ScrollableState(), initialIndex: _tabIndex),
        ),
      ),
      body: _tabIndex == 0
          ? _TeamsList(filter: _disciplineFilter)
          : _PlayersList(filter: _disciplineFilter),
    );
  }
}

class _TeamsList extends ConsumerWidget {
  final String filter;
  const _TeamsList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTeams = ref.watch(teamsStreamProvider);
    return asyncTeams.when(
      data: (teams) {
        final filtered = filter == 'Sve'
            ? teams
            : teams.where((t) => t.discipline == filter).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('Nema timova za prikaz.'));
        }
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final t = filtered[i];
            return ListTile(
              leading: const Icon(Icons.groups),
              title: Text(t.name),
              subtitle: Text('Disciplina: ${t.discipline}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  final actions = ref.read(membersActionsProvider);
                  if (value == 'edit') {
                    final newName = await _promptText(context, 'Uredi naziv tima', t.name);
                    if (newName != null && newName.trim().isNotEmpty) {
                      await actions.renameTeam(t.id, newName.trim());
                    }
                  } else if (value == 'delete') {
                    final ok = await _confirm(context, 'Obriši tim "${t.name}"?');
                    if (ok == true) await actions.deleteTeam(t.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Uredi')),
                  PopupMenuItem(value: 'delete', child: Text('Obriši')),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
    );
  }
}

class _PlayersList extends ConsumerWidget {
  final String filter;
  const _PlayersList({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPlayers = ref.watch(playersStreamProvider);
    return asyncPlayers.when(
      data: (players) {
        final filtered = filter == 'Sve'
            ? players
            : players.where((p) => p.discipline == filter).toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('Nema igrača za prikaz.'));
        }
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final p = filtered[i];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(p.name),
              subtitle: Text('Disciplina: ${p.discipline}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  final actions = ref.read(membersActionsProvider);
                  if (value == 'edit') {
                    final newName = await _promptText(context, 'Uredi ime igrača', p.name);
                    if (newName != null && newName.trim().isNotEmpty) {
                      await actions.renamePlayer(p.id, newName.trim());
                    }
                  } else if (value == 'delete') {
                    final ok = await _confirm(context, 'Obriši igrača "${p.name}"?');
                    if (ok == true) await actions.deletePlayer(p.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Uredi')),
                  PopupMenuItem(value: 'delete', child: Text('Obriši')),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
    );
  }
}

/// Helperi za dialoge
Future<String?> _promptText(BuildContext context, String title, String initial) async {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Odustani')),
        FilledButton(onPressed: () => Navigator.of(context).pop(ctrl.text), child: const Text('Spremi')),
      ],
    ),
  );
}

Future<bool?> _confirm(BuildContext context, String msg) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Potvrda'),
      content: Text(msg),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Ne')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Da')),
      ],
    ),
  );
}
