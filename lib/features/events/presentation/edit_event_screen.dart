import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/events_providers.dart';
import '../domain/event.dart';
import 'package:intl/intl.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventItem event;
  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _location;
  late TextEditingController _description;
  late TextEditingController _disciplines;
  late DateTime _dateTime;

  final _dfDate = DateFormat('dd.MM.yyyy');
  final _dfTime = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.event.name);
    _location = TextEditingController(text: widget.event.location);
    _description = TextEditingController(text: widget.event.description ?? '');
    _disciplines =
        TextEditingController(text: widget.event.disciplines.join(', '));
    _dateTime = widget.event.dateTime;
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
    final d = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        _dateTime = DateTime(
          d.year,
          d.month,
          d.day,
          _dateTime.hour,
          _dateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (t != null) {
      setState(() {
        _dateTime = DateTime(
          _dateTime.year,
          _dateTime.month,
          _dateTime.day,
          t.hour,
          t.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uredi događaj')),
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
                    label: Text(_dfDate.format(_dateTime)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_dfTime.format(_dateTime)),
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
                labelText: 'Opis',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _disciplines,
              decoration: const InputDecoration(
                labelText: 'Discipline (odvojene zarezima)',
                hintText: 'npr: 100m, Skok u dalj, LoL 5v5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final repo = ref.read(eventsRepositoryProvider);
                await repo.upsert(EventItem(
                  id: widget.event.id,
                  name: _name.text.trim(),
                  location: _location.text.trim(),
                  dateTime: _dateTime,
                  description: _description.text.trim().isEmpty
                      ? null
                      : _description.text.trim(),
                  disciplines: _disciplines.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                ));
                if (context.mounted) Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.save),
              label: const Text('Spremi'),
            ),
          ],
        ),
      ),
    );
  }
}
