import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../events/data/events_providers.dart';
import 'data/results_providers.dart';
import 'domain/result_entry.dart';
import 'presentation/add_result_screen.dart';
import 'presentation/edit_result_screen.dart';

import '../auth/data/auth_providers.dart';

// Teams
import '../teams/data/teams_providers.dart';
import '../teams/data/team_results_providers.dart';
import '../teams/presentation/add_team_screen.dart';
import '../teams/presentation/add_team_result_screen.dart';
import '../teams/domain/team_result_entry.dart';
import '../teams/domain/team.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});
  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String? _eventId;
  String? _discipline;
  String _mode = 'individual'; // or 'teams'

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final userAsync = ref.watch(authUserProvider);
    final isOrganizer = userAsync.maybeWhen(data: (u) => u?.role == 'organizer', orElse: () => false);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (events) {
        if (events.isEmpty) return const Center(child: Text('Nema evenata.'));

        _eventId ??= events.first.id;
        final selectedEvent = events.firstWhere((e) => e.id == _eventId, orElse: () => events.first);
        final disciplines = selectedEvent.disciplines;
        if (disciplines.isEmpty) return const Center(child: Text('Event nema discipline.'));
        _discipline ??= disciplines.first;

        final indivResults = ref.watch(
          resultsForEventDisciplineProvider((eventId: _eventId!, discipline: _discipline!)),
        );
        final teamResults = ref.watch(
          teamResultsForEventDisciplineProvider((eventId: _eventId!, discipline: _discipline!)),
        );
        final teams = ref.watch(teamsForEventProvider(_eventId!));

        final nf = NumberFormat('0.##');

        return Scaffold(
          appBar: AppBar(title: const Text('Rezultati')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filteri
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _eventId,
                        items: events.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                        onChanged: (v) => setState(() {
                          _eventId = v;
                          final ev = events.firstWhere((e) => e.id == v);
                          _discipline = ev.disciplines.isNotEmpty ? ev.disciplines.first : null;
                        }),
                        decoration: const InputDecoration(labelText: 'Event', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _discipline,
                        items: disciplines.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setState(() => _discipline = v),
                        decoration: const InputDecoration(labelText: 'Disciplina', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Preklopnik Individual / Teams
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'individual', label: Text('Individual')),
                      ButtonSegment(value: 'teams', label: Text('Teams')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                ),
                const SizedBox(height: 12),

                // Tablice
                Expanded(
                  child: _mode == 'individual'
                      ? _individualTable(indivResults, nf, isOrganizer)
                      : _teamsTable(teamResults, teams, nf, isOrganizer),
                ),
              ],
            ),
          ),

          // FAB akcije ovisno o modu
          floatingActionButton: isOrganizer && _eventId != null && _discipline != null
              ? (_mode == 'individual'
                  ? FloatingActionButton.extended(
                      onPressed: () async {
                        final ok = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => AddResultScreen(eventId: _eventId!, discipline: _discipline!),
                          ),
                        );
                        if (ok == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezultat dodan')));
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Dodaj rezultat'),
                    )
                  : _teamsFab(teams))
              : null,
        );
      },
    );
  }

  // ===== Individual table =====
  Widget _individualTable(List<ResultEntry> results, NumberFormat nf, bool isOrganizer) {
    return results.isEmpty
        ? const Center(child: Text('Nema individualnih rezultata.'))
        : SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Sudionik')),
                DataColumn(label: Text('Rezultat')),
                DataColumn(label: Text('')),
              ],
              rows: [
                for (int i = 0; i < results.length; i++)
                  DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text(results[i].participant)),
                    DataCell(Text('${nf.format(results[i].value)} ${results[i].unit}')),
                    DataCell(_rowMenuIndividual(results[i], isOrganizer)),
                  ])
              ],
            ),
          );
  }

  Widget _rowMenuIndividual(ResultEntry r, bool isOrganizer) {
    if (!isOrganizer) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      onSelected: (v) async {
        if (v == 'edit') {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => EditResultScreen(entry: r)),
          );
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezultat ažuriran')));
            setState(() {});
          }
        } else if (v == 'delete') {
          ref.read(resultsRepositoryProvider).delete(r.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rezultat obrisan')));
          }
          setState(() {});
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Uredi')),
        PopupMenuItem(value: 'delete', child: Text('Obriši')),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  // ===== Teams table =====
  Widget _teamsTable(List<TeamResultEntry> results, List<Team> teams, NumberFormat nf, bool isOrganizer) {
    String teamName(String id) => teams.firstWhere((t) => t.id == id, orElse: () => Team(id: 'x', eventId: '', name: 'Nepoznat', members: [])).name;

    return results.isEmpty
        ? const Center(child: Text('Nema ekipnih rezultata.'))
        : SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Tim')),
                DataColumn(label: Text('Rezultat')),
              ],
              rows: [
                for (int i = 0; i < results.length; i++)
                  DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text(teamName(results[i].teamId))),
                    DataCell(Text('${nf.format(results[i].value)} ${results[i].unit}')),
                  ])
              ],
            ),
          );
  }

  // FAB za teams: ako nema timova -> gumb "Dodaj tim", inače "Dodaj ekipni rezultat" + long-press za uređivanje timova (po želji)
  Widget _teamsFab(List<Team> teams) {
    if (teams.isEmpty) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => AddTeamScreen(eventId: _eventId!)),
          );
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tim dodan')));
            setState(() {});
          }
        },
        icon: const Icon(Icons.group_add),
        label: const Text('Dodaj tim'),
      );
    }
    return FloatingActionButton.extended(
      onPressed: () async {
        final ok = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => AddTeamResultScreen(eventId: _eventId!, discipline: _discipline!)),
        );
        if (ok == true && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ekipni rezultat dodan')));
          setState(() {});
        }
      },
      icon: const Icon(Icons.groups),
      label: const Text('Dodaj ekipni rezultat'),
    );
  }
}
