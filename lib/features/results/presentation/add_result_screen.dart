import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../events/data/events_providers.dart';
import '../../results/data/results_providers.dart';

class AddResultScreen extends ConsumerStatefulWidget {
  final String? preselectedEventId;
  final String? preselectedDiscipline;
  const AddResultScreen({super.key, this.preselectedEventId, this.preselectedDiscipline});

  @override
  ConsumerState<AddResultScreen> createState() => _AddResultScreenState();
}

class _AddResultScreenState extends ConsumerState<AddResultScreen> {
  final _formKey = GlobalKey<FormState>();
  final _participant = TextEditingController();
  final _value = TextEditingController();
  final _unit = TextEditingController(text: 'pts');
  String? _eventId;
  String? _discipline;

  @override
  void dispose() {
    _participant.dispose();
    _value.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _eventId == null || _discipline == null) return;
    ref.read(resultsRepositoryProvider).add(
      eventId: _eventId!,
      discipline: _discipline!,
      participant: _participant.text.trim(),
      value: double.parse(_value.text.trim()),
      unit: _unit.text.trim(),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj rezultat')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška: $e')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('Nema evenata — dodaj event prvo.'));
          }
          _eventId ??= widget.preselectedEventId ?? events.first.id;
          final selectedEvent = events.firstWhere((e) => e.id == _eventId, orElse: () => events.first);
          final disciplines = (selectedEvent.disciplines.isEmpty)
              ? const ['Općenito']
              : selectedEvent.disciplines;
          _discipline ??= widget.preselectedDiscipline ?? disciplines.first;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: _eventId,
                  items: [
                    for (final e in events)
                      DropdownMenuItem(value: e.id, child: Text(e.name)),
                  ],
                  onChanged: (v) => setState(() {
                    _eventId = v;
                    final ev = events.firstWhere((e) => e.id == v);
                    final ds = ev.disciplines.isEmpty ? const ['Općenito'] : ev.disciplines;
                    _discipline = ds.first;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Event',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _discipline,
                  items: [
                    for (final d in disciplines)
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (v) => setState(() => _discipline = v),
                  decoration: const InputDecoration(
                    labelText: 'Disciplina',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _participant,
                  decoration: const InputDecoration(
                    labelText: 'Sudionik',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Obavezno' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _value,
                  decoration: const InputDecoration(
                    labelText: 'Rezultat (broj)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Obavezno';
                    return double.tryParse(v.trim()) == null ? 'Unesi broj (npr. 12.5)' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Jedinica (pts, s, cm...)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Spremi'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
