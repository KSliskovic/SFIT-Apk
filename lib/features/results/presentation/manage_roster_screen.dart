import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/roster_controller.dart';
import 'package:sumfit/core/forms/validators.dart';
import 'package:sumfit/core/ui/notify.dart';
import 'roster_list_screen.dart';

// NOVO: Discipline iz centralne kolekcije
import '../data/discipline_providers.dart';

class ManageRosterScreen extends ConsumerStatefulWidget {
  const ManageRosterScreen({super.key});

  @override
  ConsumerState<ManageRosterScreen> createState() => _ManageRosterScreenState();
}

class _ManageRosterScreenState extends ConsumerState<ManageRosterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _teamName = TextEditingController();
  String? _teamDisciplineName; // ime iz dropdowna

  final _playerName = TextEditingController();
  String? _playerDisciplineName; // ime iz dropdowna

  final _teamForm = GlobalKey<FormState>();
  final _playerForm = GlobalKey<FormState>();

  bool _savingTeam = false;
  bool _savingPlayer = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _teamName.dispose();
    _playerName.dispose();
    super.dispose();
  }

  Future<void> _submitTeam() async {
    if (!_teamForm.currentState!.validate()) return;

    // Provjera discipline (mora biti timska)
    final discs = ref.read(disciplinesStreamProvider).value ?? const [];
    final d = discs.firstWhere(
      (x) => x.name == _teamDisciplineName,
      orElse: () => (discs.isEmpty ? null : discs.first)!,
    );
    if (d == null) return showError(context, 'Odaberi disciplinu');
    if (!d.isTeam) return showError(context, 'Za tim moraš odabrati TIMSKU disciplinu');

    setState(() => _savingTeam = true);
    try {
      await ref.read(rosterControllerProvider.notifier).addTeam(
        name: _teamName.text.trim(),
        discipline: d.name, // zasad spremamo ime (prijelazno)
      );
      if (!mounted) return;
      showSuccess(context, 'Tim dodan');
      _teamName.clear();
      _teamDisciplineName = null;
      setState(() {});
    } catch (e) {
      if (mounted) showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _savingTeam = false);
    }
  }

  Future<void> _submitPlayer() async {
    if (!_playerForm.currentState!.validate()) return;

    // Provjera discipline (mora biti individualna)
    final discs = ref.read(disciplinesStreamProvider).value ?? const [];
    final d = discs.firstWhere(
      (x) => x.name == _playerDisciplineName,
      orElse: () => (discs.isEmpty ? null : discs.first)!,
    );
    if (d == null) return showError(context, 'Odaberi disciplinu');
    if (d.isTeam) return showError(context, 'Za igrača moraš odabrati INDIVIDUALNU disciplinu');

    setState(() => _savingPlayer = true);
    try {
      await ref.read(rosterControllerProvider.notifier).addPlayer(
        name: _playerName.text.trim(),
        discipline: d.name, // zasad spremamo ime (prijelazno)
      );
      if (!mounted) return;
      showSuccess(context, 'Igrač dodan');
      _playerName.clear();
      _playerDisciplineName = null;
      setState(() {});
    } catch (e) {
      if (mounted) showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _savingPlayer = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discsAV = ref.watch(disciplinesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj tim/igrača'),
        actions: [
          IconButton(
            tooltip: 'Lista timova',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RosterListScreen(showTeams: true)),
              );
            },
            icon: const Icon(Icons.groups_2),
          ),
          IconButton(
            tooltip: 'Lista igrača',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RosterListScreen(showTeams: false)),
              );
            },
            icon: const Icon(Icons.person_search),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Tim'),
            Tab(text: 'Igrač'),
          ],
        ),
      ),
      body: discsAV.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška s disciplinama: $e')),
        data: (discs) => TabBarView(
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
                      decoration: const InputDecoration(
                        labelText: 'Naziv tima',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => requireText(v, label: 'Naziv tima'),
                      enabled: !_savingTeam,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _teamDisciplineName,
                      isExpanded: true,
                      items: [
                        for (final d in discs)
                          DropdownMenuItem(
                            value: d.name,
                            child: Text('${d.name} ${d.isTeam ? "(timski)" : "(individualni)"}'),
                          ),
                      ],
                      onChanged: _savingTeam ? null : (v) => setState(() => _teamDisciplineName = v),
                      decoration: const InputDecoration(
                        labelText: 'Disciplina',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Odaberi disciplinu' : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _savingTeam ? null : _submitTeam,
                      icon: _savingTeam
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
                      decoration: const InputDecoration(
                        labelText: 'Ime i prezime',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => requireText(v, label: 'Ime i prezime'),
                      enabled: !_savingPlayer,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _playerDisciplineName,
                      isExpanded: true,
                      items: [
                        for (final d in discs)
                          DropdownMenuItem(
                            value: d.name,
                            child: Text('${d.name} ${d.isTeam ? "(timski)" : "(individualni)"}'),
                          ),
                      ],
                      onChanged: _savingPlayer ? null : (v) => setState(() => _playerDisciplineName = v),
                      decoration: const InputDecoration(
                        labelText: 'Disciplina',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Odaberi disciplinu' : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _savingPlayer ? null : _submitPlayer,
                      icon: _savingPlayer
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_savingPlayer ? 'Spremanje…' : 'Spremi igrača'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
