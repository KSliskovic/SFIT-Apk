import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/discipline.dart';
import '../data/discipline_providers.dart';
import '../data/discipline_repository.dart';

class ManageDisciplinesScreen extends ConsumerWidget {
  const ManageDisciplinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAV = ref.watch(disciplinesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discipline')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Dodaj disciplinu'),
      ),
      body: listAV.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška: $e')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Nema disciplina. Dodaj novu.'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = items[i];
                  return ListTile(
                    leading: Icon(d.isTeam ? Icons.groups_2 : Icons.person),
                    title: Text(d.name),
                    subtitle: Text(d.isTeam ? 'Timski sport' : 'Individualni sport'),
                    trailing: Wrap(spacing: 8, children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Uredi',
                        onPressed: () => _openEditor(context, ref, d),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Obriši',
                        onPressed: () => _confirmDelete(context, ref, d),
                      ),
                    ]),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, [Discipline? d]) async {
    final nameCtrl = TextEditingController(text: d?.name ?? '');
    bool isTeam = d?.isTeam ?? false;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setStateSB) => AlertDialog(
            title: Text(d == null ? 'Nova disciplina' : 'Uredi disciplinu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Naziv'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Timski sport'),
                  value: isTeam,
                  onChanged: (v) => setStateSB(() => isTeam = v),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Spremi')),
            ],
          ),
        ),
      );

      if (result == true) {
        final repo = ref.read(disciplineRepositoryProvider);
        final name = nameCtrl.text.trim();
        if (name.isEmpty) return;

        if (d == null) {
          await repo.add(name: name, isTeam: isTeam);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dodano')));
        } else {
          await repo.update(d.id, name: name, isTeam: isTeam);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ažurirano')));
        }
      }
    } finally {
      nameCtrl.dispose();
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Discipline d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši disciplinu'),
        content: const Text('Brisanjem discipline možda ćete morati ažurirati povezane mečeve/roster.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Obriši')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(disciplineRepositoryProvider).delete(d.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obrisano')));
      }
    }
  }
}
