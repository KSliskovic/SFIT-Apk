import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Events
import '../../events/data/events_providers.dart';
import '../../events/domain/event.dart';

// Results (repo/provideri i add screen)
import '../data/results_providers.dart'; // teamsStreamProvider / playersStreamProvider
import '../domain/models.dart'; // Team, Player, TeamMatch, IndividualMatch
import 'add_result_screen.dart';
import 'manage_roster_guard.dart';
import 'roster_list_screen.dart';
import 'standings_screen.dart';

// Discipline (centralni izvor + helperi)
import '../data/discipline_providers.dart';   // <-- koristi stream svih disciplina + isTeam helper

// Shared standings provideri — alias da izbjegnemo sudar imena
import '../data/standings_providers.dart' as standings;

// Permissions (role-based)
import '../../../core/auth/permissions.dart';

// (opcija) ulaz za CRUD disciplina iz AppBara
import 'manage_disciplines_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  String? _eventId;
  String? _discipline; // 'Sve' ili konkretna

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final canEdit = ref.watch(canEditProvider);

    // Puni dropdown iz Firestore kolekcije: disciplines
    final discsAV = ref.watch(disciplinesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezultati'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Discipline',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageDisciplinesScreen()),
                );
              },
              icon: const Icon(Icons.category),
            ),
          if (canEdit)
            IconButton(
              tooltip: 'Vidi timove',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RosterListScreen(showTeams: true)),
                );
              },
              icon: const Icon(Icons.groups_2),
            ),
          if (canEdit)
            IconButton(
              tooltip: 'Vidi članove',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RosterListScreen(showTeams: false)),
                );
              },
              icon: const Icon(Icons.people_alt),
            ),
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
      floatingActionButton: eventsAsync.maybeWhen(
        data: (events) => (events.isEmpty || !canEdit)
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddResultScreen(
                        preselectedEventId: _eventId ?? events.first.id,
                        preselectedDiscipline: (_discipline == null || _discipline == 'Sve') ? null : _discipline,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Dodaj rezultat'),
              ),
        orElse: () => null,
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Greška s eventima: $e')),
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('Nema evenata — dodaj event prvo.'));
          }
          _eventId ??= events.first.id;

          return discsAV.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Greška s disciplinama: $e')),
            data: (discs) {
              // Dropdown lista imena: 'Sve' + iz kolekcije
              final disciplineNames = <String>['Sve', ...discs.map((d) => d.name)];
              _discipline ??= disciplineNames.first; // default 'Sve'

              final isAllSelected = _discipline == 'Sve';
              // odredi je li timsko iz odabrane discipline (ako nije 'Sve')
              final isTeam = ref.watch(disciplineIsTeamByNameProvider(isAllSelected ? null : _discipline)) ?? false;

              // Header: dropdown + search + standings
              final header = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _discipline,
                          isExpanded: true,
                          items: [
                            for (final name in disciplineNames)
                              DropdownMenuItem(value: name, child: Text(name)),
                          ],
                          onChanged: (v) => setState(() => _discipline = v),
                          decoration: const InputDecoration(
                            labelText: 'Disciplina',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ✅ nema više "Timski prikaz" switcha (auto po disciplini)
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: isAllSelected
                          ? 'Pretraži…'
                          : (isTeam ? 'Pretraži po nazivu tima…' : 'Pretraži po imenu igrača…'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                FocusScope.of(context).unfocus();
                              },
                              icon: const Icon(Icons.clear),
                              tooltip: 'Obriši pretragu',
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: isAllSelected
                          ? null
                          : () {
                              final disc = _discipline!;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StandingsScreen(
                                    initialDiscipline: disc,
                                    initialTeamsMode: isTeam, // iz discipline
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Tablica poretka'),
                    ),
                  ),
                  const Divider(),
                ],
              );

              // Body
              Widget body;
              if (isAllSelected) {
                body = const Center(
                  child: Text('Odaberi konkretnu disciplinu za prikaz mečeva.'),
                );
              } else {
                body = isTeam
                    ? _TeamSection(discipline: _discipline!, query: _query)
                    : _IndivSection(discipline: _discipline!, query: _query);
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    header,
                    Expanded(child: body),
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

class _TeamSection extends ConsumerWidget {
  final String discipline; // konkretna
  final String query;
  const _TeamSection({required this.discipline, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsVal = ref.watch(teamsStreamProvider);
    final matchesVal = ref.watch(standings.teamMatchesStreamProvider);

    final teams = teamsVal.value ?? const <Team>[];
    final matches = matchesVal.value ?? const <TeamMatch>[];

    String teamName(String id) =>
        (teams.firstWhere(
          (t) => t.id == id,
          orElse: () => const Team(id: '-', name: '—', discipline: '—'),
        )).name;

    final filtered = matches.where((m) {
      if (m.discipline != discipline) return false;
      if (query.isEmpty) return true;
      final a = teamName(m.teamAId).toLowerCase();
      final b = teamName(m.teamBId).toLowerCase();
      final q = query.toLowerCase();
      return a.contains(q) || b.contains(q);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final errorText = teamsVal.hasError
        ? 'Greška s timovima: ${teamsVal.error}'
        : (matchesVal.hasError ? 'Greška s mečevima (timski): ${matchesVal.error}' : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(errorText, style: const TextStyle(color: Colors.red)),
          ),
        if (filtered.isEmpty)
          const Expanded(child: Center(child: Text('Nema mečeva za zadane filtere.')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length.clamp(0, 1000),
              itemBuilder: (_, i) {
                final m = filtered[i];
                final a = teamName(m.teamAId);
                final b = teamName(m.teamBId);
                final date = DateFormat('dd.MM.yyyy. HH:mm').format(m.date);
                return _MatchCard(
                  leftName: a,
                  rightName: b,
                  scoreA: m.scoreA,
                  scoreB: m.scoreB,
                  discipline: m.discipline,
                  dateLabel: date,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _IndivSection extends ConsumerWidget {
  final String discipline;
  final String query;
  const _IndivSection({required this.discipline, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersVal = ref.watch(playersStreamProvider);
    final matchesVal = ref.watch(standings.indivMatchesStreamProvider);

    final players = playersVal.value ?? const <Player>[];
    final matches = matchesVal.value ?? const <IndividualMatch>[];

    String playerName(String id) =>
        (players.firstWhere(
          (p) => p.id == id,
          orElse: () => const Player(id: '-', name: '—', discipline: '—'),
        )).name;

    final filtered = matches.where((m) {
      if (m.discipline != discipline) return false;
      if (query.isEmpty) return true;
      final a = playerName(m.playerAId).toLowerCase();
      final b = playerName(m.playerBId).toLowerCase();
      final q = query.toLowerCase();
      return a.contains(q) || b.contains(q);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final errorText = playersVal.hasError
        ? 'Greška s igračima: ${playersVal.error}'
        : (matchesVal.hasError ? 'Greška s mečevima (individualno): ${matchesVal.error}' : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(errorText, style: const TextStyle(color: Colors.red)),
          ),
        if (filtered.isEmpty)
          const Expanded(child: Center(child: Text('Nema mečeva za zadane filtere.')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length.clamp(0, 1000),
              itemBuilder: (_, i) {
                final m = filtered[i];
                final a = playerName(m.playerAId);
                final b = playerName(m.playerBId);
                final date = DateFormat('dd.MM.yyyy. HH:mm').format(m.date);
                return _MatchCard(
                  leftName: a,
                  rightName: b,
                  scoreA: m.scoreA,
                  scoreB: m.scoreB,
                  discipline: m.discipline,
                  dateLabel: date,
                );
              },
            ),
          ),
      ],
    );
  }
}

/// ---------- UI: Kartica meča ----------
class _MatchCard extends StatelessWidget {
  final String leftName;
  final String rightName;
  final int scoreA;
  final int scoreB;
  final String discipline;
  final String dateLabel;

  const _MatchCard({
    required this.leftName,
    required this.rightName,
    required this.scoreA,
    required this.scoreB,
    required this.discipline,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDraw = scoreA == scoreB;
    final leftWins = scoreA > scoreB;
    final rightWins = scoreB > scoreA;

    Color badgeColor;
    if (isDraw) {
      badgeColor = theme.colorScheme.outlineVariant;
    } else {
      badgeColor = theme.colorScheme.primary;
    }

    final textStyleName = theme.textTheme.titleMedium!;
    final textStyleScore =
        theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w700);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Text(
              '$discipline • $dateLabel',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    leftName,
                    textAlign: TextAlign.center,
                    style: leftWins
                        ? textStyleName.copyWith(fontWeight: FontWeight.w700)
                        : textStyleName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text('$scoreA : $scoreB', style: textStyleScore),
                  ),
                ),
                Expanded(
                  child: Text(
                    rightName,
                    textAlign: TextAlign.center,
                    style: rightWins
                        ? textStyleName.copyWith(fontWeight: FontWeight.w700)
                        : textStyleName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(isDraw ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: badgeColor.withOpacity(0.5)),
              ),
              child: Text(
                isDraw
                    ? 'Neriješeno'
                    : (leftWins ? 'Pobjednik: $leftName' : 'Pobjednik: $rightName'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDraw
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
