import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discipline_providers.dart';
import '../domain/discipline.dart';

class ManageDisciplinesScreen extends ConsumerWidget {
  const ManageDisciplinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(disciplinesStreamProvider);
    final repo = ref.watch(disciplineRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Discipline')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final d = await _editDialog(context);
          if (d != null) repo.add(d.$1, isTeam: d.$2);
        },
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nema disciplina. Dodaj novu (+).'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = items[i];
              return Card(
                child: ListTile(
                  leading: Icon(d.isTeam ? Icons.group : Icons.person),
                  title: Text(d.name),
                  subtitle: Text(d.isTeam ? 'Timska' : 'Individualna'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final upd = await _editDialog(context, initial: d);
                        if (upd != null) {
                          repo.update(d.copyWith(name: upd.$1, isTeam: upd.$2));
                        }
                      } else if (v == 'del') {
                        final ok = await _confirm(context, 'Obrisati "${d.name}"?');
                        if (ok == true) repo.remove(d.id);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Uredi')),
                      PopupMenuItem(value: 'del', child: Text('Obriši')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<(String,bool)?> _editDialog(BuildContext ctx, {Discipline? initial}) {
  final nameCtrl = TextEditingController(text: initial?.name ?? '');
  bool isTeam = initial?.isTeam ?? true;

  return showDialog<(String,bool)>(
    context: ctx,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (dCtx, setState) {
          return AlertDialog(
            title: Text(initial == null ? 'Nova disciplina' : 'Uredi disciplinu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Naziv', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        value: true,
                        groupValue: isTeam,
                        onChanged: (v) {
                          if (v != null) setState(() => isTeam = v);
                        },
                        title: const Text('Timska'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        value: false,
                        groupValue: isTeam,
                        onChanged: (v) {
                          if (v != null) setState(() => isTeam = v);
                        },
                        title: const Text('Individualna'),
                      ),
                    ),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(null),
                child: const Text('Odustani'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.of(dialogCtx, rootNavigator: true).pop((name, isTeam));
                },
                child: const Text('Spremi'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<bool?> _confirm(BuildContext ctx, String msg) {
  return showDialog<bool>(
    context: ctx,
    builder: (dCtx) => AlertDialog(
      title: const Text('Potvrda'),
      content: Text(msg),
      actions: [
        TextButton(onPressed: ()=> Navigator.of(dCtx, rootNavigator: true).pop(false), child: const Text('Ne')),
        FilledButton(onPressed: ()=> Navigator.of(dCtx, rootNavigator: true).pop(true), child: const Text('Da')),
      ],
    ),
  );
}
