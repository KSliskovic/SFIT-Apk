import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../events/data/events_providers.dart';

class EventDetailsScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId));
    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Event')),
        body: const Center(child: Text('Event nije pronađen')),
      );
    }

    final dfDate = DateFormat('EEEE, d. MMM yyyy', 'hr');
    final dfTime = DateFormat('HH:mm', 'hr');

    final hasStart = event.startAt != null;
    final hasEnd = event.endAt != null;

    String whenText;
    if (hasStart && hasEnd) {
      final sameDay = event.startAt!.year == event.endAt!.year &&
          event.startAt!.month == event.endAt!.month &&
          event.startAt!.day == event.endAt!.day;
      whenText = sameDay
          ? '${dfDate.format(event.startAt!)} • ${dfTime.format(event.startAt!)}–${dfTime.format(event.endAt!)}'
          : '${dfDate.format(event.startAt!)} ${dfTime.format(event.startAt!)}'
          ' → ${dfDate.format(event.endAt!)} ${dfTime.format(event.endAt!)}';
    } else if (hasStart) {
      whenText = '${dfDate.format(event.startAt!)} • ${dfTime.format(event.startAt!)}';
    } else {
      whenText = 'Datum još nije postavljen';
    }

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.location?.isNotEmpty == true ? event.location! : 'Lokacija nije postavljena',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule),
              const SizedBox(width: 8),
              Expanded(
                child: Text(whenText, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          // Ovdje može ići description/discipline kada ih dodaš u model:
          // Text(event.description ?? '—', style: const TextStyle(fontSize: 16)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prijava poslana (mock)')),
          );
        },
        icon: const Icon(Icons.app_registration),
        label: const Text('Prijavi se'),
      ),
    );
  }
}
