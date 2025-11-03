import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/data/auth_providers.dart';
import '../data/events_providers.dart';
import '../domain/event.dart';
import 'create_event_screen.dart';
import 'edit_event_screen.dart';
import 'add_event_guard.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final me = ref.watch(currentUserProvider).value; // može biti null dok se učitava

    return Scaffold(
      appBar: AppBar(
        title: const Text('Događaji'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final e = items[i];
              final canEdit = me?.role == 'organizer' && me?.uid == e.ownerUid;

              return _EventCard(
                event: e,
                onTap: () {
                  // samo organizator/owner uredjuje; ostali samo pregled (ako želiš)
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EditEventScreen(event: e)),
                  );
                },
                showOwnerBadge: canEdit,
              );
            },
          );
        },
      ),
      floatingActionButton: AddEventGuard(
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateEventScreen()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Dodaj događaj'),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventItem event;
  final VoidCallback onTap;
  final bool showOwnerBadge;

  const _EventCard({
    required this.event,
    required this.onTap,
    required this.showOwnerBadge,
  });

  @override
  Widget build(BuildContext context) {
    final date = _formatRange(event.startAt, event.endAt);
    final location = (event.location?.isNotEmpty ?? false) ? event.location! : 'Lokacija nije postavljena';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // naslov + badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showOwnerBadge)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Moje',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // lokacija
              Row(
                children: [
                  Icon(Icons.place, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // datum range kao chip
              Wrap(
                spacing: 8,
                runSpacing: -6,
                children: [
                  _chip(context, Icons.event, date),
                  if (event.endAt == null)
                    _chip(context, Icons.schedule, 'Jednodnevni'),
                ],
              ),

              if (event.description != null && event.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  event.description!.trim(),
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatRange(DateTime? start, DateTime? end) {
    final d = DateFormat('d.M.y.', 'hr');
    if (start == null && end == null) return 'Datum nije postavljen';
    if (start != null && end != null) {
      final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
      return sameDay ? d.format(start) : '${d.format(start)} – ${d.format(end)}';
    }
    final s = start ?? end!;
    return d.format(s);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy, size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'Nema događaja još.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Dodaj prvi događaj pomoću gumba dolje desno.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
