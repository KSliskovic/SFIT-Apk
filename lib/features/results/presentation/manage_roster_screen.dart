import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/roster_controller.dart';
import 'package:sumfit/core/forms/validators.dart';
import 'package:sumfit/core/ui/notify.dart';
import 'roster_list_screen.dart';

class ManageRosterScreen extends ConsumerStatefulWidget {
  const ManageRosterScreen({super.key});

  @override
  ConsumerState<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends ConsumerState<ManageRosterScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _teamName = TextEditingController();
  final _teamDiscipline = TextEditingController();
  final _playerName = TextEditingController();
  final _playerDiscipline = TextEditingController();
  final _teamForm = GlobalKey<FormState>();
  final _playerForm = GlobalKey<FormState>();
  bool _savingTeam = false;
  bool _savingPlayer = false;

  @override
  void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override
  void dispose() {
    _tab.dispose();
    _teamName.dispose(); _teamDiscipline.dispose();
    _playerName.dispose(); _playerDiscipline.dispose();
    super.dispose();
  }

  Future<void> _submitTeam() async {
    if (!_teamForm.currentState!.validate()) return;
    setState(() => _savingTeam = true);
    final res = await ref.read(rosterControllerProvider.notifier).addTeam(
      name: _teamName.text.trim(), discipline: _teamDiscipline.text.trim(),
    );
    if (!mounted) return;
    setState(() => _savingTeam = false);
    res.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Tim dodan'); _teamName.clear(); _teamDiscipline.clear();
    });
  }

  Future<void> _submitPlayer() async {
    if (!_playerForm.currentState!.validate()) return;
    setState(() => _savingPlayer = true);
    final res = await ref.read(rosterControllerProvider.notifier).addPlayer(
      name: _playerName.text.trim(), discipline: _playerDiscipline.text.trim(),
    );
    if (!mounted) return;
    setState(() => _savingPlayer = false);
    res.fold((f) => showError(context, f.message), (_) {
      showSuccess(context, 'Igrač dodan'); _playerName.clear(); _playerDiscipline.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj tim/igrača'),
        actions: [
          IconButton(
            tooltip: 'Lista timova',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RosterListScreen(showTeams: true)));
            },
            icon: const Icon(Icons.groups_2),
          ),
          IconButton(
            tooltip: 'Lista igrača',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RosterListScreen(showTeams: false)));
            },
            icon: const Icon(Icons.person_search),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [ Tab(text: 'Tim'), Tab(text: 'Igrač') ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // TIM
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _teamForm,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _teamName,
                    decoration: const InputDecoration(labelText: 'Naziv tima', border: OutlineInputBorder()),
                    validator: (v) => requireText(v, label: 'Naziv tima'),
                    enabled: !_savingTeam,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _teamDiscipline,
                    decoration: const InputDecoration(labelText: 'Disciplina', border: OutlineInputBorder()),
                    validator: (v) => requireText(v, label: 'Disciplina'),
                    enabled: !_savingTeam,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _savingTeam ? null : _submitTeam,
                    icon: _savingTeam
                        ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2))
                        : const Icon(Icons.save),
                    label: Text(_savingTeam ? 'Spremanje…' : 'Spremi tim'),
                  ),
                ],
              ),
            ),
          ),
          // IGRAČ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _playerForm,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _playerName,
                    decoration: const InputDecoration(labelText: 'Ime i prezime', border: OutlineInputBorder()),
                    validator: (v) => requireText(v, label: 'Ime i prezime'),
                    enabled: !_savingPlayer,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _playerDiscipline,
                    decoration: const InputDecoration(labelText: 'Disciplina', border: OutlineInputBorder()),
                    validator: (v) => requireText(v, label: 'Disciplina'),
                    enabled: !_savingPlayer,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _savingPlayer ? null : _submitPlayer,
                    icon: _savingPlayer
                        ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2))
                        : const Icon(Icons.save),
                    label: Text(_savingPlayer ? 'Spremanje…' : 'Spremi igrača'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
