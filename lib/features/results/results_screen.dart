// lib/features/results/results_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// events
import '../events/data/events_providers.dart';

// results (individual)
import 'data/results_providers.dart';
import 'domain/result_entry.dart';
import 'presentation/add_result_screen.dart';
import 'presentation/edit_result_screen.dart';

// auth (for organizer role)
import '../auth/data/auth_providers.dart';

// teams (teams & team results)
import '../teams/data/teams_providers.dart';
import '../teams/data/team_results_providers.dart';
import '../teams/presentation/add_team_screen.dart';
import '../teams/presentation/add_team_result_screen.dart';
import '../teams/domain/team_result_entry.dart';
import '../teams/domain/team.dart';

// central disciplines list
import 'data/disciplines.dart';

// upravljanje rosterom (1 ekran s tabovima Tim/Igrač)
import 'presentation/manage_roster_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});
  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String? _eventId;
  String? _discipline; // "Svi" ili konkretna disciplina
  String _mode = 'individual'; // 'individual' | 'teams'

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isOrganizer = userAsync.maybeWhen(
      data: (u) => u?.role == 'organizer',
      orElse: () => false,
    );

    final allDisciplines = ref.watch(allDisciplinesProvider);
    final disciplines = allDisciplines.isEmpty
        ? const <String>[]
        : (allDisciplines.first == 'Svi' ? allDisciplines : ['Svi', ...allDisciplines]);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Greška: $e')),
      data: (events) {
        if (events.isEmpty) return const Center(child: Text('Nema evenata.'));

        _eventId ??= events.first.id;
        _discipline ??= (disciplines.isNotEmpty ? disciplines.first : null);

        // podaci
        final indivResults = ref
            .watch(resultsForEventDisciplineProvider((
        eventId: _eventId!,
        discipline: _discipline == 'Svi' ? null : _discipline!
        )))
            .maybeWhen(data: (l) => l, orElse: () => <ResultEntry>[]);

        final teamResults = ref
            .watch(teamResultsForEventDisciplineProvider((
        eventId: _eventId!,
        discipline: _discipline == 'Svi' ? null : _discipline!
        )))
            .maybeWhen(data: (l) => l, orElse: () => <TeamResultEntry>[]);

        final teams = ref
            .watch(teamsForEventProvider(_eventId!))
            .maybeWhen(data: (l) => l, orElse: () => <Team>[]);

        final nf = NumberFormat('0.##');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rezultati'),
            // 👇 ove ikone vide SAMO organizatori
            actions: isOrganizer
                ? [
              // Prikaži timove
              IconButton(
                tooltip: 'Timovi / Igrači',
                icon: const Icon(Icons.groups),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManageRosterScreen()),
                  );
                },
              ),
              // (po želji) brzi dodaci tima/igrača:
              // IconButton(tooltip:'Dodaj tim', icon: const Icon(Icons.group_add), onPressed: () { ... })
              // IconButton(tooltip:'Dodaj igrača', icon: const Icon(Icons.person_add), onPressed: () { ... }),
            ]
                : null,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // filteri
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _eventId,
                        items: [
                          for (final e in events)
                            DropdownMenuItem(value: e.id, child: Text(e.title)),
                        ],
                        onChanged: (v) => setState(() => _eventId = v),
                        decoration: const InputDecoration(
                          labelText: 'Event',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _discipline,
                        items: [
                          for (final d in disciplines)
                            DropdownMenuItem(value: d, child: Text(d)),
                        ],
                        onChanged: (v) => setState(() => _discipline = v),
                        decoration: const InputDecoration(
                          labelText: 'Disciplina',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // preklop: individual / timovi
                Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'individual', label: Text('Individual')),
                      ButtonSegment(value: 'teams', label: Text('Timovi')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: _mode == 'individual'
                      ? _individualTable(indivResults, nf, isOrganizer)
                      : _teamsTable(teamResults, teams, nf),
                ),
              ],
            ),
          ),

          // 👇 i FAB je samo za organizatora
          floatingActionButton: isOrganizer && _eventId != null && _discipline != null
              ? (_mode == 'individual'
              ? FloatingActionButton.extended(
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => AddResultScreen(
                    preselectedEventId: _eventId!,
                    preselectedDiscipline:
                    _discipline == 'Svi' ? null : _discipline!,
                  ),
                ),
              );
              if (ok == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rezultat dodan')),
                );
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
  Widget _individualTable(
      List<ResultEntry> results,
      NumberFormat nf,
      bool isOrganizer,
      ) {
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
              // 👇 student nema “more” meni
              DataCell(isOrganizer ? _rowMenuIndividual(results[i]) : const SizedBox.shrink()),
            ])
        ],
      ),
    );
  }

  Widget _rowMenuIndividual(ResultEntry r) {
    return PopupMenuButton<String>(
      onSelected: (v) async {
        if (v == 'edit') {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => EditResultScreen(entry: r)),
          );
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Rezultat ažuriran')));
            setState(() {});
          }
        } else if (v == 'delete') {
          ref.read(resultsRepositoryProvider).delete(r.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Rezultat obrisan')));
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
  Widget _teamsTable(List<TeamResultEntry> results, List<Team> teams, NumberFormat nf) {
    String teamName(String id) {
      final t = teams.firstWhere(
            (t) => t.id == id,
        orElse: () => Team(id: 'x', eventId: '', name: 'Nepoznat', members: const []),
      );
      return t.name;
    }

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

  // Teams FAB (samo kad je organizator i postoje timovi)
  Widget _teamsFab(List<Team> teams) {
    if (teams.isEmpty) {
      return FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => AddTeamScreen(eventId: _eventId!)),
          );
          if (ok == true && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tim dodan')),
            );
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
          MaterialPageRoute(
            builder: (_) => AddTeamResultScreen(
              eventId: _eventId!,
              discipline: _discipline == 'Svi' ? null : _discipline!,
            ),
          ),
        );
        if (ok == true && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Ekipni rezultat dodan')));
          setState(() {});
        }
      },
      icon: const Icon(Icons.groups),
      label: const Text('Dodaj ekipni rezultat'),
    );
  }
}
