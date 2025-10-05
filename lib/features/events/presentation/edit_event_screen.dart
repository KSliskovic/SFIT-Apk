import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/events_controller.dart';
import '../domain/event.dart';
import 'package:sumfit/core/forms/validators.dart';
import 'package:sumfit/core/ui/notify.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventItem event;
  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _disciplines = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  DateTime? _dateTime;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _name.text = e.name;
    _disciplines.text = e.disciplines.join(', ');
    _location.text = e.location ?? '';
    _description.text = e.description ?? '';
    _dateTime = e.dateTime;
  }

  @override
  void dispose() {
    _name.dispose();
    _disciplines.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final base = _dateTime ?? DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Odaberi datum',
    );
    if (d == null) return;
    setState(() {
      _dateTime = DateTime(d.year, d.month, d.day, base.hour, base.minute);
    });
  }

  Future<void> _pickTime() async {
    final base = _dateTime ?? DateTime.now();
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Odaberi vrijeme',
    );
    if (t == null) return;
    setState(() {
      _dateTime = DateTime(base.year, base.month, base.day, t.hour, t.minute);
    });
  }

  List<String> _parseDisciplines() {
    return _disciplines.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateTime == null) {
      showError(context, 'Odaberi datum i vrijeme');
      return;
    }

    final ctrl = ref.read(eventsControllerProvider.notifier);
    final item = EventItem(
      id: widget.event.id,
      name: _name.text.trim(),
      dateTime: _dateTime!,
      disciplines: _parseDisciplines(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
    );

    final res = await ctrl.upsert(item);
    if (!mounted) return;
    res.fold(
      (f) => showError(context, f.message),
      (_) {
        showSuccess(context, 'Event spremljen');
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obriši event'),
        content: const Text('Jesi siguran da želiš obrisati ovaj event?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Obriši')),
        ],
      ),
    );
    if (ok != true) return;

    final res = await ref.read(eventsControllerProvider.notifier).delete(widget.event.id);
    if (!mounted) return;
    res.fold(
      (f) => showError(context, f.message),
      (_) {
        showSuccess(context, 'Event obrisan');
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsControllerProvider);
    final isLoading = state.isLoading;

    final dt = _dateTime;
    final dtLabel = dt == null
        ? '—'
        : DateFormat('dd.MM.yyyy. HH:mm').format(dt);

    return Scaffold(
      appBar: AppBar(title: const Text('Uredi event')),
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
              validator: (v) => requireText(v, label: 'Naziv'),
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Datum'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: const Text('Vrijeme'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Odabrano: $dtLabel'),

            const SizedBox(height: 12),
            TextFormField(
              controller: _disciplines,
              decoration: const InputDecoration(
                labelText: 'Discipline (odvojene zarezom)',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Lokacija',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Opis',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !isLoading,
            ),

            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isLoading ? null : _save,
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(isLoading ? 'Spremanje…' : 'Spremi'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _delete,
              icon: const Icon(Icons.delete),
              label: const Text('Obriši'),
            ),
          ],
        ),
      ),
    );
  }
}
