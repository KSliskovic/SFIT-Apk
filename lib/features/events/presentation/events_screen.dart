import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/events_providers.dart';
import '../domain/event.dart';
import '../../auth/data/auth_providers.dart';
import 'create_event_screen.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(eventsStreamProvider);
    final userAsync = ref.watch(authUserProvider);
    final isOrganizer = userAsync.when(
      data: (u) => u?.role == 'organizer',
      loading: () => false,
      error: (_, __) => false,
    );

    final df = DateFormat('EEE, d. MMM yyyy • HH:mm', 'hr');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Događaji'),
        actions: [
          if (isOrganizer)
            IconButton(
              tooltip: 'Novi event',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
                if (ok == true && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Event dodan')));
                }
              },
            ),
        ],
      ),
      body: asyncEvents.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy, size: 64),
                    const SizedBox(height: 12),
                    const Text('Nema događaja još 😴', style: TextStyle(fontSize: 18)),
                    if (isOrganizer) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          final ok = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                          );
                          if (ok == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Event dodan')),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Dodaj prvi event'),
                      ),
                    ]
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = events[i];
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.event, size: 32),
                  title: Text(e.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  subtitle: Text('${df.format(e.dateTime)}\n${e.location}'
                      '${(e.description != null && e.description!.isNotEmpty) ? '\n${e.description!}' : ''}'
                      '${e.disciplines.isNotEmpty ? '\nDiscipline: ${e.disciplines.join(', ')}' : ''}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška: $e')),
      ),
      floatingActionButton: isOrganizer
          ? FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
                if (ok == true && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Event dodan')));
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
