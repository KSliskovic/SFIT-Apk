import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/events_providers.dart';
import '../domain/event.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventItem event;
  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  DateTime? _startAt;
  DateTime? _endAt;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.event.title);
    _location = TextEditingController(text: widget.event.location ?? '');
    _startAt = widget.event.startAt;
    _endAt = widget.event.endAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final init = (start ? _startAt : _endAt) ?? now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: init,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startAt = DateTime(picked.year, picked.month, picked.day);
        if (_endAt != null && _endAt!.isBefore(_startAt!)) _endAt = _startAt;
      } else {
        _endAt = DateTime(picked.year, picked.month, picked.day);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.event.copyWith(
      title: _title.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      startAt: _startAt,
      endAt: _endAt,
    );
    await ref.read(eventsActionsProvider).upsert(updated);
    if (!mounted) return;
    Navigator.of(context).pop('updated');
  }

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Obriši event'),
        content: Text('Sigurno obrisati "${widget.event.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(false), child: const Text('Ne')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(d).pop(true),
            child: const Text('Da, obriši'),
          ),
        ],
      ),
    );
    if (yes == true) {
      await ref.read(eventsActionsProvider).deleteEvent(widget.event.id!);
      if (!mounted) return;
      Navigator.of(context).pop('deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Uredi događaj')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Naziv', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Unesite naziv' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Lokacija (opcionalno)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_startAt == null
                        ? 'Početak'
                        : '${_startAt!.day}.${_startAt!.month}.${_startAt!.year}.'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: false),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(_endAt == null
                        ? 'Kraj (opcionalno)'
                        : '${_endAt!.day}.${_endAt!.month}.${_endAt!.year}.'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Akcije
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Spremi'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Obriši'),
              style: TextButton.styleFrom(
                foregroundColor: cs.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
