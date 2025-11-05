import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_providers.dart';
import '../data/events_providers.dart';
import '../domain/event.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();


  DateTime? _startAt;
  DateTime? _endAt;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();

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
        if (_startAt != null && _endAt!.isBefore(_startAt!)) _endAt = _startAt;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final me = ref.read(currentUserProvider).value;
    if (me == null) {
      _toast('Niste prijavljeni.');
      return;
    }
    if (_startAt == null) {
      _toast('Odaberite početni datum.');
      return;
    }



    final item = EventItem(
      id: null,
      title: _title.text.trim(),
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      startAt: _startAt!,
      endAt: _endAt,
      ownerUid: me.uid,
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),

    );

    await ref.read(eventsActionsProvider).upsert(item);
    if (!mounted) return;
    Navigator.of(context).pop(true); // vrati true da roditelj zna da je spremljeno
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Događaj kreiran')),
    );
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novi događaj')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Naziv',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Unesite naziv' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Lokacija (opcionalno)',
                border: OutlineInputBorder(),
              ),
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


            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: true),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startAt == null
                          ? 'Početak'
                          : '${_startAt!.day}.${_startAt!.month}.${_startAt!.year}.',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(start: false),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      _endAt == null
                          ? 'Kraj (opcionalno)'
                          : '${_endAt!.day}.${_endAt!.month}.${_endAt!.year}.',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Spremi'),
            ),
          ],
        ),
      ),
    );
  }
}
