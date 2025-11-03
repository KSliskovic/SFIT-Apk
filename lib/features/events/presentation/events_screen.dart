import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/events_providers.dart';
import '../../../core/auth/permissions.dart';
import 'add_event_guard.dart';
import 'create_event_screen.dart'; // 👈 dodaj ovo

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(canEditProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    String _fmtRange(DateTime? start, DateTime? end) {
      if (start == null && end == null) return 'Datum nije postavljen';
      final dDate = DateFormat('dd.MM.yyyy.', 'hr');
      final dTime = DateFormat('HH:mm', 'hr');
      if (start != null && end != null) {
        final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
        return sameDay
            ? '${dDate.format(start)} • ${dTime.format(start)}–${dTime.format(end)}'
            : '${dDate.format(start)} ${dTime.format(start)} → ${dDate.format(end)} ${dTime.format(end)}';
      }
      final s = start ?? end!;
      return '${dDate.format(s)} • ${dTime.format(s)}';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Eventi')),

      // ✅ Guard oko FAB-a (ne push-a se AddEventGuard)
      floatingActionButton: AddEventGuard(
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateEventScreen()),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),

      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška: $e')),
        data: (events) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final e = events[i];
            return ListTile(
              title: Text(e.title),
              subtitle: Text(_fmtRange(e.startAt, e.endAt)), // ✅ umjesto e.date
              // onTap: ... (otvori detalje ili edit, po želji)
            );
          },
        ),
      ),
    );
  }
}
