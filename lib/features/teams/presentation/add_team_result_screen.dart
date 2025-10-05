import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../teams/data/teams_providers.dart';
import '../../teams/data/team_results_providers.dart';
import '../../teams/domain/team_result_entry.dart';
import '../../../core/id.dart';

class AddTeamResultScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String discipline;
  const AddTeamResultScreen({super.key, required this.eventId, required this.discipline});

  @override
  ConsumerState<AddTeamResultScreen> createState() => _AddTeamResultScreenState();
}

class _AddTeamResultScreenState extends ConsumerState<AddTeamResultScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _teamId;
  final _value = TextEditingController();
  final _unit = TextEditingController(text: 'pts');

  @override
  void dispose() {
    _value.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate() || _teamId == null) return;
    final repo = ref.read(teamResultsRepositoryProvider);
    repo.add(TeamResultEntry(
      id: newId('tr'),
      eventId: widget.eventId,
      discipline: widget.discipline,
      teamId: _teamId!,
      value: double.parse(_value.text.trim()),
      unit: _unit.text.trim(),
    ));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final teams = ref.watch(teamsForEventProvider(widget.eventId));

    _teamId ??= (teams.isNotEmpty ? teams.first.id : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Dodaj ekipni rezultat')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _teamId,
              items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
              onChanged: (v) => setState(() => _teamId = v),
              decoration: const InputDecoration(labelText: 'Tim', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _value,
              decoration: const InputDecoration(labelText: 'Rezultat (broj)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v==null || v.trim().isEmpty) return 'Obavezno';
                return double.tryParse(v.trim())==null ? 'Unesi broj (npr. 3, 12.5)' : null;
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
