import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/events_providers.dart';
import 'edit_event_screen.dart';
import 'create_event_screen.dart';

class ManageEventsScreen extends ConsumerWidget {
  const ManageEventsScreen({super.key});

  String _fmtRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Datum nije postavljen';
    final dDate = DateFormat('dd.MM.yyyy.', 'hr');
    final dTime = DateFormat('HH:mm', 'hr');
    if (start != null && end != null) {
      final sameDay =
          start.year == end.year && start.month == end.month && start.day == end.day;
      return sameDay
          ? '${dDate.format(start)} • ${dTime.format(start)}–${dTime.format(end)}'
          : '${dDate.format(start)} ${dTime.format(start)} → ${dDate.format(end)} ${dTime.format(end)}';
    }
    final s = start ?? end!;
    return '${dDate.format(s)} • ${dTime.format(s)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);

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
              final loc = (e.location?.isNotEmpty ?? false) ? e.location! : '—';
              final when = _fmtRange(e.startAt, e.endAt);

              Future<void> openEdit() async {
                final result = await Navigator.of(c).push<String?>(
                  MaterialPageRoute(builder: (_) => EditEventScreen(event: e)),
                );
                if (!c.mounted) return;
                if (result == 'deleted') {
                  ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Event obrisan')));
                } else if (result == 'updated') {
                  ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Event ažuriran')));
                }
              }

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(e.title),
                  subtitle: Text('$loc • $when'),
                  onTap: openEdit, // Samo tap otvara uređivanje
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event dodan')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
