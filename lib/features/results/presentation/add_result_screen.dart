import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../events/data/events_providers.dart';
import '../../events/domain/event.dart';

import '../data/results_providers.dart';
import '../data/results_repository.dart';
import '../domain/models.dart';
import '../application/results_controller.dart';

import 'package:sumfit/core/ui/notify.dart';
import 'manage_roster_guard.dart';

// Discipline (centralni izvor)
import '../data/disciplines.dart';

// Permissions (role-based)
import '../../../core/auth/permissions.dart';

class AddResultScreen extends ConsumerStatefulWidget {
  final String? preselectedEventId;
  final String? preselectedDiscipline;
  const AddResultScreen({super.key, this.preselectedEventId, this.preselectedDiscipline});

  @override
  ConsumerState<AddResultScreen> createState() => _AddResultScreenState();
}

class _AddResultScreenState extends ConsumerState<AddResultScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _eventId;
  String? _discipline;
  bool _isTeam = false; // false => individualni; true => timski

  String? _playerA;
  String? _playerB;
  String? _teamA;
  String? _teamB;

  final _scoreA = TextEditingController();
  final _scoreB = TextEditingController();
  DateTime? _date;
  bool _saving = false;

  @override
  void dispose() {
    _scoreA.dispose();
    _scoreB.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final base = _date ?? now;

    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Odaberi datum',
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Odaberi vrijeme',
    );
    if (t == null) return;

    setState(() {
      _date = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  String? _validateScore(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obavezno';
    return int.tryParse(v.trim()) == null ? 'Unesi cijeli broj' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventId == null) return showError(context, 'Odaberi event');
    if (_discipline == null) return showError(context, 'Odaberi disciplinu');
    if (_date == null) return showError(context, 'Odaberi datum/vrijeme');
    setState(() => _saving = true);

    try {
      final scoreA = int.parse(_scoreA.text.trim());
      final scoreB = int.parse(_scoreB.text.trim());
      final ctrl = ref.read(resultsControllerProvider.notifier);

      if (_isTeam) {
        if (_teamA == null || _teamB == null) { setState(() => _saving = false); return showError(context, 'Odaberi oba tima'); }
        if (_teamA == _teamB) { setState(() => _saving = false); return showError(context, 'Tim A i Tim B moraju biti različiti'); }

        final res = await ctrl.addTeamMatch(
          discipline: _discipline!, teamAId: _teamA!, teamBId: _teamB!,
          scoreA: scoreA, scoreB: scoreB, date: _date,
        );
        if (!mounted) return;
        res.fold(
          (f) { setState(() => _saving = false); showError(context, f.message); },
          (_) { showSuccess(context, 'Rezultat (tim) spremljen'); Navigator.of(context).pop(); },
        );
      } else {
        if (_playerA == null || _playerB == null) { setState(() => _saving = false); return showError(context, 'Odaberi oba igrača'); }
        if (_playerA == _playerB) { setState(() => _saving = false); return showError(context, 'Igrač A i Igrač B moraju biti različiti'); }

        final res = await ctrl.addIndividualMatch(
          discipline: _discipline!, playerAId: _playerA!, playerBId: _playerB!,
          scoreA: scoreA, scoreB: scoreB, date: _date,
        );
        if (!mounted) return;
        res.fold(
          (f) { setState(() => _saving = false); showError(context, f.message); },
          (_) { showSuccess(context, 'Rezultat (individualni) spremljen'); Navigator.of(context).pop(); },
        );
      }
    } catch (e) {
      if (mounted) { setState(() => _saving = false); showError(context, e.toString()); }
    }
  }

  @override
  Widget build(BuildContext context) {
    // RBAC: studenti ne mogu uopće vidjeti formu
    final canEdit = ref.watch(canEditProvider);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dodaj rezultat')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Samo organizatori mogu dodavati rezultate.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final eventsAsync = ref.watch(eventsStreamProvider);
    final playersAsync = ref.watch(playersStreamProvider);
    final teamsAsync = ref.watch(teamsStreamProvider);

    // Centralne discipline (bez "Sve"!)
    final disciplines = ref.watch(allDisciplinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj rezultat'),
        actions: [
          // Gumb za dodavanje tim/igrača prikazujemo SAMO organizatoru
          if (canEdit)
            IconButton(
              tooltip: 'Dodaj tim/igrača',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageRosterGuard()),
                );
              },
              icon: const Icon(Icons.group_add),
            ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška s eventima: $e')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('Nema evenata — dodaj event prvo.'));
          }

          _eventId ??= widget.preselectedEventId ?? events.first.id;
          _discipline ??= widget.preselectedDiscipline ?? (disciplines.isNotEmpty ? disciplines.first : null);

          final dtLabel = _date == null
              ? '—'
              : DateFormat('dd.MM.yyyy. HH:mm').format(_date!);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  value: _eventId,
                  isExpanded: true,
                  items: [ for (final e in events) DropdownMenuItem(value: e.id, child: Text(e.name)) ],
                  onChanged: (v) => setState(() => _eventId = v),
                  decoration: const InputDecoration(labelText: 'Event', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _discipline,
                  isExpanded: true,
                  items: [ for (final d in disciplines) DropdownMenuItem(value: d, child: Text(d)) ],
                  onChanged: (v) => setState(() => _discipline = v),
                  decoration: const InputDecoration(labelText: 'Disciplina', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.event),
                        label: const Text('Datum i vrijeme'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Odabrano: $dtLabel', maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SwitchListTile(
                  title: const Text('Timski rezultat'),
                  value: _isTeam,
                  onChanged: (v) => setState(() => _isTeam = v),
                ),
                const SizedBox(height: 8),

                if (_isTeam)
                  teamsAsync.when(
                    loading: () => const Center(child: Text('Učitavanje timova…')),
                    error: (e, _) => Center(child: Text('Greška s timovima: $e')),
                    data: (teams) {
                      if (teams.isEmpty) return const Text('Nema timova — dodaj ih (ikona gore desno).');
                      _teamA ??= teams.first.id;
                      _teamB ??= teams.length > 1 ? teams[1].id : teams.first.id;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _teamA, isExpanded: true,
                                  items: [ for (final t in teams) DropdownMenuItem(value: t.id, child: Text(t.name)) ],
                                  onChanged: (v) => setState(() => _teamA = v),
                                  decoration: const InputDecoration(labelText: 'Tim A', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _teamB, isExpanded: true,
                                  items: [ for (final t in teams) DropdownMenuItem(value: t.id, child: Text(t.name)) ],
                                  onChanged: (v) => setState(() => _teamB = v),
                                  decoration: const InputDecoration(labelText: 'Tim B', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _scoreA,
                                  decoration: const InputDecoration(labelText: 'Rezultat A', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number, validator: _validateScore,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _scoreB,
                                  decoration: const InputDecoration(labelText: 'Rezultat B', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number, validator: _validateScore,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  )
                else
                  playersAsync.when(
                    loading: () => const Center(child: Text('Učitavanje igrača…')),
                    error: (e, _) => Center(child: Text('Greška s igračima: $e')),
                    data: (players) {
                      if (players.isEmpty) return const Text('Nema igrača — dodaj ih (ikona gore desno).');
                      _playerA ??= players.first.id;
                      _playerB ??= players.length > 1 ? players[1].id : players.first.id;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _playerA, isExpanded: true,
                                  items: [ for (final p in players) DropdownMenuItem(value: p.id, child: Text(p.name)) ],
                                  onChanged: (v) => setState(() => _playerA = v),
                                  decoration: const InputDecoration(labelText: 'Igrač A', border: OutlineInputBorder()),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _playerB, isExpanded: true,
                                  items: [ for (final p in players) DropdownMenuItem(value: p.id, child: Text(p.name)) ],
                                  onChanged: (v) => setState(() => _playerB = v),
                                  decoration: const InputDecoration(labelText: 'Igrač B', border: OutlineInputBorder()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _scoreA,
                                  decoration: const InputDecoration(labelText: 'Rezultat A', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number, validator: _validateScore,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _scoreB,
                                  decoration: const InputDecoration(labelText: 'Rezultat B', border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number, validator: _validateScore,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Spremanje…' : 'Spremi'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
