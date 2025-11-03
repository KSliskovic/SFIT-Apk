// lib/features/results/presentation/standings_screen.dart
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../data/standings_providers.dart' as standings;
import '../data/disciplines.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  final String initialDiscipline; // npr. "Sve" ili "Košarka"
  final bool initialTeamsMode;    // false = individual, true = timovi

  const StandingsScreen({
    super.key,
    required this.initialDiscipline,
    this.initialTeamsMode = false,
  });

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  late String _discipline;
  late bool _teamsMode;

  @override
  void initState() {
    super.initState();
    _discipline = widget.initialDiscipline;
    _teamsMode = widget.initialTeamsMode;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allDisciplines = ref.watch(allDisciplinesWithAllProvider);

    // Dinamički dohvat poretka prema filterima
    final rowsAV = _teamsMode
        ? ref.watch(standings.teamStandingsProvider(_discipline))
        : ref.watch(standings.individualStandingsProvider(_discipline));

    final title =
        'Tablica poretka • ${_teamsMode ? 'Timovi' : 'Individual'} • $_discipline';

    final textNum = theme.textTheme.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget header() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: _discipline,
                isExpanded: true,
                items: [
                  for (final d in allDisciplines)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _discipline = v);
                },
                decoration: const InputDecoration(
                  labelText: 'Disciplina',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Timski prikaz'),
                value: _teamsMode,
                onChanged: (v) => setState(() => _teamsMode = v),
              ),
            ),
          ],
        ),
      );
    }

    DataTable buildTable(List<TableRowEntry> rows) {
      return DataTable(
        headingTextStyle: theme.textTheme.labelLarge,
        dataTextStyle: theme.textTheme.bodyMedium,
        headingRowHeight: 44,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 44,
        columnSpacing: 20,
        showBottomBorder: true,
        columns: const [
          DataColumn(label: Text('#')),
          DataColumn(label: Text('Ime')),
          DataColumn(label: Text('Uta.'), numeric: true),
          DataColumn(label: Text('Pob.'), numeric: true),
          DataColumn(label: Text('Ner.'), numeric: true),
          DataColumn(label: Text('Por.'), numeric: true),
          DataColumn(label: Text('GF'), numeric: true),
          DataColumn(label: Text('GA'), numeric: true),
          DataColumn(label: Text('+/-'), numeric: true),
          DataColumn(label: Text('Bod.'), numeric: true),
        ],
        rows: [
          for (int i = 0; i < rows.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}', style: textNum)),
                DataCell(Text(rows[i].name, overflow: TextOverflow.ellipsis)),
                DataCell(Text('${rows[i].played}', style: textNum)),
                DataCell(Text('${rows[i].wins}', style: textNum)),
                DataCell(Text('${rows[i].draws}', style: textNum)),
                DataCell(Text('${rows[i].losses}', style: textNum)),
                DataCell(Text('${rows[i].goalsFor}', style: textNum)),
                DataCell(Text('${rows[i].goalsAgainst}', style: textNum)),
                DataCell(Text('${rows[i].diff}', style: textNum)),
                DataCell(Text('${rows[i].points}', style: textNum)),
              ],
            ),
        ],
      );
    }

    Widget tableContainer(Widget child) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 720),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          header(),
          Expanded(
            child: rowsAV.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Greška: $e')),
              data: (rows) => rows.isEmpty
                  ? const Center(child: Text('Nema podataka za prikaz.'))
                  : tableContainer(buildTable(rows)),
            ),
          ),
        ],
      ),
    );
  }
}
