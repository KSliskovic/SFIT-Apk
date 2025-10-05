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
    final df = DateFormat('EEEE, d. MMM yyyy • HH:mm', 'hr');

    return Scaffold(
      appBar: AppBar(title: Text(event.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.place),
              const SizedBox(width: 8),
              Text(event.location, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule),
              const SizedBox(width: 8),
              Text(df.format(event.date), style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(event.description, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          const Divider(),
          const Text('Discipline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: -6,
            children: event.disciplines
                .map((d) => Chip(label: Text(d)))
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: prijava na event (mock)
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
