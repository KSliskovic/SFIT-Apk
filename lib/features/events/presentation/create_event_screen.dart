import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/events_providers.dart';
import '../domain/event.dart';
import '../../../core/id.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final EventItem? editing;
  const CreateEventScreen({super.key, this.editing});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _disciplines;
  DateTime? _dateTime;

  final _dfDate = DateFormat('d. MMM yyyy', 'hr');
  final _dfTime = DateFormat('HH:mm', 'hr');

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _name = TextEditingController(text: e?.name ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _disciplines = TextEditingController(text: (e?.disciplines ?? []).join(', '));
    _dateTime = e?.dateTime;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _description.dispose();
    _disciplines.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _dateTime ?? now,
      helpText: 'Odaberi datum',
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime?.hour ?? 12,
        _dateTime?.minute ?? 0,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime ?? DateTime.now()),
      helpText: 'Odaberi vrijeme',
    );
    if (picked == null) return;
    setState(() {
      final base = _dateTime ?? DateTime.now();
      _dateTime = DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odaberi datum i vrijeme')),
      );
      return;
    }
    final actions = ref.read(eventsActionsProvider);
    final List<String> discs = _disciplines.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final item = EventItem(
      id: widget.editing?.id ?? newId('event'),
      name: _name.text.trim(),
      location: _location.text.trim(),
      dateTime: _dateTime!,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      disciplines: discs,
    );

    await actions.upsert(item);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Uredi event' : 'Novi event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Naziv',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obavezno polje' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_dateTime == null
                        ? 'Datum'
                        : _dfDate.format(_dateTime!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_dateTime == null
                        ? 'Vrijeme'
                        : _dfTime.format(_dateTime!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Lokacija',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obavezno polje' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Opis (opcionalno)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _disciplines,
              decoration: const InputDecoration(
                labelText: 'Discipline (zarezom odvojene)',
                hintText: 'npr: Nogomet 5v5, Košarka, Tenis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Spremi promjene' : 'Spremi'),
            ),
          ],
        ),
      ),
    );
  }
}
