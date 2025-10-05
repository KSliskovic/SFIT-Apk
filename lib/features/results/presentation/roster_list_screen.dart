import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/results_providers.dart';
import '../data/results_repository.dart';
import '../domain/models.dart';
import 'package:sumfit/core/ui/notify.dart';

class RosterListScreen extends ConsumerStatefulWidget {
  final bool showTeams; // true = timovi; false = igraci
  const RosterListScreen({super.key, this.showTeams = true});

  @override
  ConsumerState<RosterListScreen> createState() => _RosterListScreenState();
}

class _RosterListScreenState extends ConsumerState<RosterListScreen> {
  String _query = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _renameTeam(Team t) async {
    final c = TextEditingController(text: t.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preimenuj tim'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Novi naziv'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Spremi')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      ref.read(resultsRepositoryProvider).renameTeam(t.id, newName);
      if (!mounted) return;
      showSuccess(context, 'Tim preimenovan');
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString());
    }
  }

  Future<void> _renamePlayer(Player p) async {
    final c = TextEditingController(text: p.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preimenuj igrača'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Novi naziv'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Spremi')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    try {
      ref.read(resultsRepositoryProvider).renamePlayer(p.id, newName);
      if (!mounted) return;
      showSuccess(context, 'Igrač preimenovan');
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString());
    }
  }

  Future<void> _deleteTeam(Team t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši tim'),
        content: const Text('Brisanjem tima brišu se i njegovi mečevi. Nastaviti?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Obriši')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      ref.read(resultsRepositoryProvider).deleteTeam(t.id);
      if (!mounted) return;
      showSuccess(context, 'Tim obrisan');
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString());
    }
  }

  Future<void> _deletePlayer(Player p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši igrača'),
        content: const Text('Brisanjem igrača brišu se i njegovi mečevi. Nastaviti?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Obriši')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      ref.read(resultsRepositoryProvider).deletePlayer(p.id);
      if (!mounted) return;
      showSuccess(context, 'Igrač obrisan');
    } catch (e) {
      if (!mounted) return;
      showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsStreamProvider);
    final playersAsync = ref.watch(playersStreamProvider);

    final teams = teamsAsync.value ?? const <Team>[];
    final players = playersAsync.value ?? const <Player>[];

    final err = teamsAsync.hasError
        ? 'Greška s timovima: ${teamsAsync.error}'
        : (playersAsync.hasError ? 'Greška s igračima: ${playersAsync.error}' : null);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showTeams ? 'Timovi' : 'Igrači'),
      ),
      body: Column(
        children: [
          if (err != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(err, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Pretraga po nazivu/disciplini',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: widget.showTeams
                ? _TeamsList(
                    items: teams
                        .where((t) => _query.isEmpty
                            ? true
                            : (t.name.toLowerCase().contains(_query) || t.discipline.toLowerCase().contains(_query)))
                        .toList(),
                    onRename: _renameTeam,
                    onDelete: _deleteTeam,
                  )
                : _PlayersList(
                    items: players
                        .where((p) => _query.isEmpty
                            ? true
                            : (p.name.toLowerCase().contains(_query) || p.discipline.toLowerCase().contains(_query)))
                        .toList(),
                    onRename: _renamePlayer,
                    onDelete: _deletePlayer,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context), // back to previous (npr. ManageRoster ili Results)
        icon: const Icon(Icons.check),
        label: const Text('Gotovo'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}

class _TeamsList extends StatelessWidget {
  final List<Team> items;
  final void Function(Team) onRename;
  final void Function(Team) onDelete;
  const _TeamsList({required this.items, required this.onRename, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Nema timova. Dodaj ih pa pokušaj ponovno.'));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = items[i];
        return ListTile(
          title: Text(t.name),
          subtitle: Text('Disciplina: ${t.discipline}'),
          trailing: Wrap(
            spacing: 8,
            children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => onRename(t)),
              IconButton(icon: const Icon(Icons.delete), onPressed: () => onDelete(t)),
            ],
          ),
        );
      },
    );
  }
}

class _PlayersList extends StatelessWidget {
  final List<Player> items;
  final void Function(Player) onRename;
  final void Function(Player) onDelete;
  const _PlayersList({required this.items, required this.onRename, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('Nema igrača. Dodaj ih pa pokušaj ponovno.'));
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = items[i];
        return ListTile(
          title: Text(p.name),
          subtitle: Text('Disciplina: ${p.discipline}'),
          trailing: Wrap(
            spacing: 8,
            children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () => onRename(p)),
              IconButton(icon: const Icon(Icons.delete), onPressed: () => onDelete(p)),
            ],
          ),
        );
      },
    );
  }
}
