import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/result_entry.dart';
import '../data/results_providers.dart';

class EditResultScreen extends ConsumerStatefulWidget {
  final ResultEntry entry;
  const EditResultScreen({super.key, required this.entry});

  @override
  ConsumerState<EditResultScreen> createState() => _EditResultScreenState();
}

class _EditResultScreenState extends ConsumerState<EditResultScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _participant;
  late final TextEditingController _value;
  late final TextEditingController _unit;

  @override
  void initState() {
    super.initState();
    _participant = TextEditingController(text: widget.entry.participant);
    _value = TextEditingController(text: widget.entry.value.toString());
    _unit = TextEditingController(text: widget.entry.unit);
  }

  @override
  void dispose() {
    _participant.dispose();
    _value.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(resultsRepositoryProvider);
    final valStr = _value.text.trim().replaceAll(',', '.');

    repo.update(ResultEntry(
      id: widget.entry.id,
      eventId: widget.entry.eventId,
      discipline: widget.entry.discipline,
      participant: _participant.text.trim(),
      value: double.parse(valStr),
      unit: _unit.text.trim(),
      createdAt: widget.entry.createdAt,
    ));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uredi rezultat')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Event: ${widget.entry.eventId}', style: const TextStyle(color: Colors.black54)),
            Text('Disciplina: ${widget.entry.discipline}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _participant,
              decoration: const InputDecoration(labelText: 'Sudionik', border: OutlineInputBorder()),
              validator: (v) => (v==null || v.trim().isEmpty) ? 'Obavezno' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _value,
              decoration: const InputDecoration(labelText: 'Rezultat (broj)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v==null || v.trim().isEmpty) return 'Obavezno';
                final norm = v.trim().replaceAll(',', '.');
                return double.tryParse(norm)==null ? 'Unesi broj (npr. 12.5)' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _unit,
              decoration: const InputDecoration(labelText: 'Jedinica (pts, s, cm...)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Spremi')),
          ],
        ),
      ),
    );
  }
}
