import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../events/data/events_providers.dart';

import '../data/results_providers.dart';
import '../application/results_controller.dart';
import '../domain/models.dart';

import 'package:sumfit/core/ui/notify.dart';
import 'manage_roster_guard.dart';

// NOVO: Discipline (centralni izvor)
import '../data/discipline_providers.dart';

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
  String? _disciplineName; // ime discipline (dok ne migriramo na disciplineId)
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

  Future<void> _save(bool isTeam) async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventId == null) return showError(context, 'Odaberi event');
    if (_disciplineName == null) return showError(context, 'Odaberi disciplinu');
    if (_date == null) return showError(context, 'Odaberi datum/vrijeme');

    setState(() => _saving = true);
    try {
      final scoreA = int.parse(_scoreA.text.trim());
      final scoreB = int.parse(_scoreB.text.trim());
      final ctrl = ref.read(resultsControllerProvider.notifier);

      if (isTeam) {
        if (_teamA == null || _teamB == null) { setState(() => _saving = false); return showError(context, 'Odaberi oba tima'); }
        if (_teamA == _teamB) { setState(() => _saving = false); return showError(context, 'Tim A i Tim B moraju biti različiti'); }

        await ctrl.addTeamMatch(
          discipline: _disciplineName!, teamAId: _teamA!, teamBId: _teamB!,
          scoreA: scoreA, scoreB: scoreB, date: _date, eventId: _eventId,
        );
        if (!mounted) return;
        setState(() => _saving = false);
        showSuccess(context, 'Rezultat (tim) spremljen');
        Navigator.of(context).pop();
      } else {
        if (_playerA == null || _playerB == null) { setState(() => _saving = false); return showError(context, 'Odaberi oba igrača'); }
        if (_playerA == _playerB) { setState(() => _saving = false); return showError(context, 'Igrač A i Igrač B moraju biti različiti'); }

        await ctrl.addIndividualMatch(
          discipline: _disciplineName!, playerAId: _playerA!, playerBId: _playerB!,
          scoreA: scoreA, scoreB: scoreB, date: _date, eventId: _eventId,
        );
        if (!mounted) return;
        setState(() => _saving = false);
        showSuccess(context, 'Rezultat (individualni) spremljen');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) { setState(() => _saving = false); showError(context, e.toString()); }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard po ulozi: koristi isti mehanizam kao prije, ili ga uključi kroz parent
    // (Ako želiš, može i ManageRosterGuard ovdje, ali ostavljam kao što je bilo.)
    final eventsAsync = ref.watch(eventsStreamProvider);

    // NOVO: dohvat disciplina iz centralnog izvora
    final discsAV = ref.watch(disciplinesStreamProvider);

    // Roster
    final playersAsync = ref.watch(playersStreamProvider);
    final teamsAsync = ref.watch(teamsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj rezultat'),
        actions: [
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
          // Event default
          if (events.isNotEmpty) {
            final ids = events.map((e) => e.id).toSet();
            final candidate = widget.preselectedEventId ?? _eventId ?? events.first.id;
            _eventId = ids.contains(candidate) ? candidate : events.first.id;
          } else {
            _eventId = null;
          }

          return discsAV.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Greška s disciplinama: $e')),
            data: (discs) {
              if (discs.isEmpty) {
                return const _EmptyBlock(message: 'Nema disciplina — dodaj barem jednu disciplinu.');
              }

              // Discipline default (po imenu jer modeli zasad koriste string)
              final names = discs.map((d) => d.name).toList(growable: false);
              if (names.isNotEmpty) {
                final ds = names.toSet();
                final candidate = widget.preselectedDiscipline ?? _disciplineName ?? names.first;
                _disciplineName = ds.contains(candidate) ? candidate : names.first;
              } else {
                _disciplineName = null;
              }

              // je li timska odabrana disciplina?
              final isTeam = ref.watch(disciplineIsTeamByNameProvider(_disciplineName)) ?? false;

              final dtLabel = _date == null ? '—' : DateFormat('dd.MM.yyyy. HH:mm').format(_date!);

              // Filtriraj roster prema odabranoj disciplini
              final teams = (teamsAsync.value ?? const <Team>[])
                  .where((t) => _disciplineName == null ? false : t.discipline == _disciplineName)
                  .toList();
              final players = (playersAsync.value ?? const <Player>[])
                  .where((p) => _disciplineName == null ? false : p.discipline == _disciplineName)
                  .toList();

              // pripremi default izbore (A/B) kad se promijeni disciplina
              if (isTeam) {
                if (teams.isNotEmpty) {
                  final ids = teams.map((t) => t.id).toList();
                  _teamA = (ids.contains(_teamA)) ? _teamA : ids.first;
                  _teamB = (ids.contains(_teamB))
                      ? _teamB
                      : (ids.length > 1 ? ids[1] : ids.first);
                } else {
                  _teamA = null;
                  _teamB = null;
                }
              } else {
                if (players.isNotEmpty) {
                  final ids = players.map((p) => p.id).toList();
                  _playerA = (ids.contains(_playerA)) ? _playerA : ids.first;
                  _playerB = (ids.contains(_playerB))
                      ? _playerB
                      : (ids.length > 1 ? ids[1] : ids.first);
                } else {
                  _playerA = null;
                  _playerB = null;
                }
              }

              return Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (events.isEmpty)
                      const _EmptyBlock(message: 'Nema evenata — dodaj event prvo.')
                    else
                      DropdownButtonFormField<String>(
                        value: _eventId,
                        isExpanded: true,
                        items: [
                          for (final e in events)
                            DropdownMenuItem(value: e.id, child: Text(e.title)),
                        ],
                        onChanged: (v) => setState(() => _eventId = v),
                        decoration: const InputDecoration(labelText: 'Event', border: OutlineInputBorder()),
                      ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _disciplineName,
                      isExpanded: true,
                      items: [for (final n in names) DropdownMenuItem(value: n, child: Text(n))],
                      onChanged: (v) => setState(() {
                        _disciplineName = v;
                        // reset izbora na promjeni discipline
                        _teamA = _teamB = _playerA = _playerB = null;
                      }),
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
                        Expanded(child: Text('Odabrano: $dtLabel', maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (isTeam)
                      teamsAsync.when(
                        loading: () => const Center(child: Text('Učitavanje timova…')),
                        error: (e, _) => Center(child: Text('Greška s timovima: $e')),
                        data: (_) {
                          if (teams.isEmpty) {
                            return const _EmptyBlock(message: 'Nema timova za ovu disciplinu — dodaj ih (ikona gore desno).');
                          }
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _teamA,
                                      isExpanded: true,
                                      items: [for (final t in teams) DropdownMenuItem(value: t.id, child: Text(t.name))],
                                      onChanged: (v) => setState(() => _teamA = v),
                                      decoration: const InputDecoration(labelText: 'Tim A', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _teamB,
                                      isExpanded: true,
                                      items: [for (final t in teams) DropdownMenuItem(value: t.id, child: Text(t.name))],
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
                        data: (_) {
                          if (players.isEmpty) {
                            return const _EmptyBlock(message: 'Nema igrača za ovu disciplinu — dodaj ih (ikona gore desno).');
                          }
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _playerA,
                                      isExpanded: true,
                                      items: [for (final p in players) DropdownMenuItem(value: p.id, child: Text(p.name))],
                                      onChanged: (v) => setState(() => _playerA = v),
                                      decoration: const InputDecoration(labelText: 'Igrač A', border: OutlineInputBorder()),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _playerB,
                                      isExpanded: true,
                                      items: [for (final p in players) DropdownMenuItem(value: p.id, child: Text(p.name))],
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
                      onPressed: _saving ? null : () => _save(isTeam),
                      icon: _saving
                          ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2))
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Spremanje…' : 'Spremi'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String message;
  const _EmptyBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.35)),
      ),
      child: Text(message),
    );
  }
}
