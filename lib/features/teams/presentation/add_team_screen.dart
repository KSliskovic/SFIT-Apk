import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../teams/data/teams_providers.dart';
import '../../teams/domain/team.dart';
import '../../../core/id.dart';

class AddTeamScreen extends ConsumerStatefulWidget {
  final String eventId;
  const AddTeamScreen({super.key, required this.eventId});

  @override
  ConsumerState<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends ConsumerState<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _members = TextEditingController(); // CSV

  @override
  void dispose() {
    _name.dispose();
    _members.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(teamsRepositoryProvider);
    final members = _members.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    repo.add(Team(id: newId('tm'), eventId: widget.eventId, name: _name.text.trim(), members: members));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novi tim')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Naziv tima', border: OutlineInputBorder()),
              validator: (v) => (v==null || v.trim().isEmpty) ? 'Obavezno' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _members,
              decoration: const InputDecoration(
                labelText: 'Članovi (zarezima odvojeni)',
                hintText: 'npr: Ana, Marko, Iva',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Spremi')),
          ],
        ),
      ),
    );
  }
}
