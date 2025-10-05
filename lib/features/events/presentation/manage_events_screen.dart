import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/events_providers.dart';
import '../domain/event.dart';
import 'create_event_screen.dart';

class ManageEventsScreen extends ConsumerWidget {
  const ManageEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final actions = ref.watch(eventsActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Upravljanje eventima')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška: $e')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('Nema evenata.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (c, i) {
              final e = events[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(e.name),
                  subtitle: Text('${e.location} • ${e.dateTime}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        final ok = await Navigator.of(c).push<bool>(
                          MaterialPageRoute(builder: (_) => CreateEventScreen(editing: e)),
                        );
                        if (ok == true && c.mounted) {
                          ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Event ažuriran')));
                        }
                      } else if (v == 'delete') {
                        final yes = await showDialog<bool>(
                          context: c,
                          builder: (d) => AlertDialog(
                            title: const Text('Obriši event'),
                            content: Text('Sigurno obrisati "${e.name}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('Ne')),
                              FilledButton(onPressed: () => Navigator.of(d).pop(true), child: const Text('Da')),
                            ],
                          ),
                        );
                        if (yes == true) {
                          await actions.deleteEvent(e.id);
                          if (c.mounted) {
                            ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Event obrisan')));
                          }
                        }
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
          );
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event dodan')));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
