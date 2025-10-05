import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/results_providers.dart';
import '../data/results_repository.dart';
import '../domain/models.dart';

// Events
import '../../events/data/events_providers.dart';

// Disciplines
import '../../disciplines/data/discipline_providers.dart';
import '../../disciplines/presentation/manage_disciplines_screen.dart';

// Auth (za provjeru role)
import '../../auth/data/auth_providers.dart';

DateTime? _extractEventDate(dynamic e) {
  try { final d = e.date; if (d is DateTime) return d; } catch (_) {}
  try { final d = e.dateTime; if (d is DateTime) return d; } catch (_) {}
  try { final d = e.start; if (d is DateTime) return d; } catch (_) {}
  try { final d = e.when; if (d is DateTime) return d; } catch (_) {}
  return null;
}

String _extractEventName(dynamic e) {
  try { final n = e.name; if (n is String && n.trim().isNotEmpty) return n; } catch (_) {}
  try { final n = e.title; if (n is String && n.trim().isNotEmpty) return n; } catch (_) {}
  return 'Event';
}

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> with TickerProviderStateMixin {
  late TabController _tab;

  String? _teamDiscipline;
  String? _indivDiscipline;

  DateTime? _teamEventDate;
  DateTime? _indivEventDate;

  final _df = DateFormat('EEE, d. MMM yyyy');

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // provjeri je li user organizer
    final userAsync = ref.watch(authUserProvider);
    final isOrganizer = userAsync.asData?.value?.role == 'organizer';

    final repo = ref.watch(resultsRepositoryProvider);
    final teamDisc = ref.watch(teamDisciplinesProvider);
    final indivDisc = ref.watch(individualDisciplinesProvider);

    _teamDiscipline ??= (teamDisc.isNotEmpty ? teamDisc.first.name : null);
    _indivDiscipline ??= (indivDisc.isNotEmpty ? indivDisc.first.name : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezultati'),
        actions: [
          if (isOrganizer)
            IconButton(
              tooltip: 'Upravljaj disciplinama',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ManageDisciplinesScreen()),
                );
              },
              icon: const Icon(Icons.tune),
            ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Timski sportovi'),
            Tab(text: 'Samostalni'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _TeamTab(
            discipline: _teamDiscipline,
            onChangeDiscipline: (d) => setState(() => _teamDiscipline = d),
            selectedDate: _teamEventDate,
            onChangeDate: (d) => setState(() => _teamEventDate = d),
            df: _df,
          ),
          _IndividualTab(
            discipline: _indivDiscipline,
            onChangeDiscipline: (d) => setState(() => _indivDiscipline = d),
            selectedDate: _indivEventDate,
            onChangeDate: (d) => setState(() => _indivEventDate = d),
            df: _df,
          ),
        ],
      ),
      // FAB je samo za organizatora
      floatingActionButton: !isOrganizer
          ? null
          : (_tab.index == 0
              ? _TeamFab(repo: repo, discipline: _teamDiscipline ?? '', selectedDate: _teamEventDate)
              : _IndividualFab(repo: repo, discipline: _indivDiscipline ?? '', selectedDate: _indivEventDate)),
    );
  }
}

class _EventDateFilter extends ConsumerWidget {
  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;
  final DateFormat df;
  final String hint;

  const _EventDateFilter({
    required this.selected,
    required this.onChanged,
    required this.df,
    required this.hint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    return eventsAsync.when(
      loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Greška s eventima: $e'),
      data: (events) {
        final byDay = <String, DateTime>{};
        final namesByDay = <String, Set<String>>{};
        for (final e in events) {
          final d = _extractEventDate(e);
          if (d == null) continue;
          final day = DateTime(d.year, d.month, d.day);
          final key = DateFormat('yyyy-MM-dd').format(day);

          byDay[key] = day;
          namesByDay.putIfAbsent(key, () => <String>{}).add(_extractEventName(e));
        }

        final days = byDay.values.toList()..sort((a, b) => a.compareTo(b));

        final items = <DropdownMenuItem<DateTime?>>[
          const DropdownMenuItem<DateTime?>(value: null, child: Text('Svi datumi')),
          ...days.map((d) {
            final key = DateFormat('yyyy-MM-dd').format(d);
            final names = (namesByDay[key] ?? const <String>{}).toList()..sort();
            final label = '${df.format(d)} — ${names.join(', ')}';
            return DropdownMenuItem<DateTime?>(value: d, child: Text(label));
          }),
        ];

        return DropdownButtonFormField<DateTime?>(
          value: selected,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(labelText: hint, border: const OutlineInputBorder()),
        );
      },
    );
  }
}

class _TeamTab extends ConsumerWidget {
  final String? discipline;
  final ValueChanged<String> onChangeDiscipline;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onChangeDate;
  final DateFormat df;

  const _TeamTab({
    required this.discipline,
    required this.onChangeDiscipline,
    required this.selectedDate,
    required this.onChangeDate,
    required this.df,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamDisc = ref.watch(teamDisciplinesProvider);
    final teamsAsync = ref.watch(teamsStreamProvider);
    final matchesAsync = ref.watch(teamMatchesStreamProvider);
    final table = ref.watch(teamTableProvider(discipline ?? ''));

    final discItems = teamDisc.map((d) => DropdownMenuItem(value: d.name, child: Text(d.name))).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: discItems.isEmpty
                    ? const Text('Dodaj timske discipline (gore desno • “tune” ikona).')
                    : DropdownButtonFormField<String>(
                        value: discipline,
                        items: discItems,
                        onChanged: (v) => onChangeDiscipline(v ?? (discipline ?? '')),
                        decoration: const InputDecoration(labelText: 'Disciplina', border: OutlineInputBorder()),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EventDateFilter(
                  selected: selectedDate,
                  onChanged: onChangeDate,
                  df: df,
                  hint: 'Datum (event)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _StandingsTable(entries: table),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Center(
                          child: Text('Utakmice', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 8),
                        matchesAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Greška: $e')),
                          data: (all) {
                            final teams = teamsAsync.asData?.value ?? const <Team>[];
                            final mapTeam = {for (var t in teams) t.id: t.name};

                            bool sameDay(DateTime a, DateTime b) =>
                                a.year == b.year && a.month == b.month && a.day == b.day;

                            final list = all.where((m) {
                              if ((discipline ?? '').isEmpty) return false;
                              if (m.discipline != discipline) return false;
                              if (selectedDate == null) return true;
                              return sameDay(m.date, selectedDate!);
                            }).toList()
                              ..sort((a, b) => b.date.compareTo(a.date));

                            if (list.isEmpty) {
                              return Center(
                                child: Text(selectedDate == null
                                    ? 'Nema utakmica.'
                                    : 'Nema utakmica na datum: ${df.format(selectedDate!)}'),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                for (final m in list)
                                  Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Icon(m.winner == 0 ? Icons.hourglass_empty : Icons.emoji_events),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${mapTeam[m.teamAId] ?? 'Tim A'}  ${m.scoreA} : ${m.scoreB}  ${mapTeam[m.teamBId] ?? 'Tim B'}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${df.format(m.date)} • '
                                            '${m.winner == 0 ? 'Neriješeno' : (m.winner == 1 ? 'Pobjeda: ${mapTeam[m.teamAId] ?? 'Tim A'}' : 'Pobjeda: ${mapTeam[m.teamBId] ?? 'Tim B'}')}',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IndividualTab extends ConsumerWidget {
  final String? discipline;
  final ValueChanged<String> onChangeDiscipline;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onChangeDate;
  final DateFormat df;

  const _IndividualTab({
    required this.discipline,
    required this.onChangeDiscipline,
    required this.selectedDate,
    required this.onChangeDate,
    required this.df,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indivDisc = ref.watch(individualDisciplinesProvider);
    final playersAsync = ref.watch(playersStreamProvider);
    final matchesAsync = ref.watch(individualMatchesStreamProvider);
    final table = ref.watch(individualTableProvider(discipline ?? ''));

    final discItems = indivDisc.map((d) => DropdownMenuItem(value: d.name, child: Text(d.name))).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: discItems.isEmpty
                    ? const Text('Dodaj individualne discipline (gore desno • “tune” ikona).')
                    : DropdownButtonFormField<String>(
                        value: discipline,
                        items: discItems,
                        onChanged: (v) => onChangeDiscipline(v ?? (discipline ?? '')),
                        decoration: const InputDecoration(labelText: 'Disciplina', border: OutlineInputBorder()),
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EventDateFilter(
                  selected: selectedDate,
                  onChanged: onChangeDate,
                  df: df,
                  hint: 'Datum (event)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _StandingsTable(entries: table),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: matchesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Greška: $e')),
                      data: (all) {
                        final players = playersAsync.asData?.value ?? const <Player>[];
                        final mapP = {for (var p in players) p.id: p.name};

                        bool sameDay(DateTime a, DateTime b) =>
                            a.year == b.year && a.month == b.month && a.day == b.day;

                        final list = all.where((m) {
                          if ((discipline ?? '').isEmpty) return false;
                          if (m.discipline != discipline) return false;
                          if (selectedDate == null) return true;
                          return sameDay(m.date, selectedDate!);
                        }).toList()
                          ..sort((a, b) => b.date.compareTo(a.date));

                        if (list.isEmpty) {
                          return Center(
                            child: Text(selectedDate == null
                                ? 'Nema mečeva.'
                                : 'Nema mečeva na datum: ${df.format(selectedDate!)}'),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Center(
                              child: Text('Mečevi', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 8),
                            for (final m in list)
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(m.winner == 0 ? Icons.hourglass_empty : Icons.emoji_events),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${mapP[m.playerAId] ?? 'Igrač A'}  ${m.scoreA} : ${m.scoreB}  ${mapP[m.playerBId] ?? 'Igrač B'}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${df.format(m.date)} • '
                                        '${m.winner == 0 ? 'Neriješeno' : (m.winner == 1 ? 'Pobjeda: ${mapP[m.playerAId] ?? 'Igrač A'}' : 'Pobjeda: ${mapP[m.playerBId] ?? 'Igrač B'}')}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<TableRowEntry> entries;
  const _StandingsTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Text('Nema podataka za tablicu.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Naziv')),
          DataColumn(label: Text('UT')),
          DataColumn(label: Text('P')),
          DataColumn(label: Text('N')),
          DataColumn(label: Text('I')),
          DataColumn(label: Text('BOD')),
          DataColumn(label: Text('+')),
          DataColumn(label: Text('-')),
          DataColumn(label: Text('DIF')),
        ],
        rows: [
          for (int i = 0; i < entries.length; i++)
            DataRow(cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Text(entries[i].name)),
              DataCell(Text('${entries[i].played}')),
              DataCell(Text('${entries[i].wins}')),
              DataCell(Text('${entries[i].draws}')),
              DataCell(Text('${entries[i].losses}')),
              DataCell(Text('${entries[i].points}')),
              DataCell(Text('${entries[i].goalsFor}')),
              DataCell(Text('${entries[i].goalsAgainst}')),
              DataCell(Text('${entries[i].diff}')),
            ]),
        ],
      ),
    );
  }
}

class _TeamFab extends ConsumerWidget {
  final ResultsRepository repo;
  final String discipline;
  final DateTime? selectedDate;

  const _TeamFab({required this.repo, required this.discipline, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add),
      onSelected: (v) async {
        if (v == 'team') {
          final name = await _promptText(context, 'Novi tim', 'Naziv tima');
          if (name != null && name.trim().isNotEmpty) {
            repo.addTeam(name.trim(), discipline);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tim "${name.trim()}" dodan')),
              );
            }
          }
        } else if (v == 'match') {
          final teams = await ref.read(teamsStreamProvider.future);
          final inDisc = teams.where((t) => t.discipline == discipline).toList();
          if (inDisc.length < 2) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dodaj barem 2 tima za utakmicu.')),
              );
            }
            return;
          }
          final data = await _matchDialog(context, inDisc);
          if (data != null) {
            repo.addTeamMatch(
              discipline: discipline,
              teamAId: data.$1,
              teamBId: data.$2,
              scoreA: data.$3,
              scoreB: data.$4,
              date: selectedDate,
            );
            if (context.mounted) {
              final msg = selectedDate == null
                  ? 'Utakmica dodana'
                  : 'Utakmica dodana za ${DateFormat('d.MM.yyyy').format(selectedDate!)}';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            }
          }
        }
      },
      itemBuilder: (c) => const [
        PopupMenuItem(value: 'team', child: Text('Dodaj tim')),
        PopupMenuItem(value: 'match', child: Text('Dodaj utakmicu')),
      ],
    );
  }
}

class _IndividualFab extends ConsumerWidget {
  final ResultsRepository repo;
  final String discipline;
  final DateTime? selectedDate;

  const _IndividualFab({required this.repo, required this.discipline, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add),
      onSelected: (v) async {
        if (v == 'player') {
          final name = await _promptText(context, 'Novi igrač', 'Ime i prezime');
          if (name != null && name.trim().isNotEmpty) {
            repo.addPlayer(name.trim(), discipline);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Igrač "${name.trim()}" dodan')),
              );
            }
          }
        } else if (v == 'match') {
          final players = await ref.read(playersStreamProvider.future);
          final inDisc = players.where((p) => p.discipline == discipline).toList();
          if (inDisc.length < 2) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dodaj barem 2 igrača za meč.')),
              );
            }
            return;
          }
          final data = await _indMatchDialog(context, inDisc);
          if (data != null) {
            repo.addIndividualMatch(
              discipline: discipline,
              playerAId: data.$1,
              playerBId: data.$2,
              scoreA: data.$3,
              scoreB: data.$4,
              date: selectedDate,
            );
            if (context.mounted) {
              final msg = selectedDate == null
                  ? 'Meč dodan'
                  : 'Meč dodan za ${DateFormat('d.MM.yyyy').format(selectedDate!)}';
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
            }
          }
        }
      },
      itemBuilder: (c) => const [
        PopupMenuItem(value: 'player', child: Text('Dodaj igrača')),
        PopupMenuItem(value: 'match', child: Text('Dodaj meč')),
      ],
    );
  }
}

Future<String?> _promptText(BuildContext context, String title, String label) async {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, decoration: InputDecoration(labelText: label)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(null),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(ctrl.text),
          child: const Text('Spremi'),
        ),
      ],
    ),
  );
}

Future<(String,String,int,int)?> _matchDialog(BuildContext context, List<Team> teams) async {
  String? aId = teams.first.id;
  String? bId = teams.length > 1 ? teams[1].id : teams.first.id;
  final aCtrl = TextEditingController(text: '0');
  final bCtrl = TextEditingController(text: '0');

  return showDialog<(String,String,int,int)>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Nova utakmica'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: aId,
            items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
            onChanged: (v) => aId = v,
            decoration: const InputDecoration(labelText: 'Tim A'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: bId,
            items: teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
            onChanged: (v) => bId = v,
            decoration: const InputDecoration(labelText: 'Tim B'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: aCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rezultat A'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: bCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rezultat B'))),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(null),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            if (aId == null || bId == null || aId == bId) return;
            final sa = int.tryParse(aCtrl.text) ?? 0;
            final sb = int.tryParse(bCtrl.text) ?? 0;
            Navigator.of(dialogCtx, rootNavigator: true).pop((aId!, bId!, sa, sb));
          },
          child: const Text('Spremi'),
        ),
      ],
    ),
  );
}

Future<(String,String,int,int)?> _indMatchDialog(BuildContext context, List<Player> players) async {
  String? aId = players.first.id;
  String? bId = players.length > 1 ? players[1].id : players.first.id;
  final aCtrl = TextEditingController(text: '0');
  final bCtrl = TextEditingController(text: '0');

  return showDialog<(String,String,int,int)>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Novi meč'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: aId,
            items: players.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (v) => aId = v,
            decoration: const InputDecoration(labelText: 'Igrač A'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: bId,
            items: players.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (v) => bId = v,
            decoration: const InputDecoration(labelText: 'Igrač B'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: aCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rezultat A'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: bCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rezultat B'))),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(null),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            if (aId == null || bId == null || aId == bId) return;
            final sa = int.tryParse(aCtrl.text) ?? 0;
            final sb = int.tryParse(bCtrl.text) ?? 0;
            Navigator.of(dialogCtx, rootNavigator: true).pop((aId!, bId!, sa, sb));
          },
          child: const Text('Spremi'),
        ),
      ],
    ),
  );
}
