import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/disciplines.dart';
import '../domain/models.dart';
import '../data/standings_providers.dart';

class StandingsScreen extends ConsumerStatefulWidget {
  final String initialDiscipline; // npr. 'Sve' ili 'Nogomet'
  final bool initialIsTeam;       // true = timski, false = individualni

  const StandingsScreen({
    super.key,
    required this.initialDiscipline,
    required this.initialIsTeam,
  });

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  late String _discipline;
  late bool _isTeam;

  // sort state
  int _sortColumnIndex = 5; // default Pts
  bool _sortAsc = false;    // veći bodovi gore

  @override
  void initState() {
    super.initState();
    _discipline = widget.initialDiscipline;
    _isTeam = widget.initialIsTeam;
  }

  @override
  Widget build(BuildContext context) {
    final allDisciplines = ref.watch(allDisciplinesWithAllProvider);

    final rows = _isTeam
        ? ref.watch(teamTableProvider(_discipline))
        : ref.watch(indivTableProvider(_discipline));

    // primijeni sortiranje
    final data = [...rows];
    int cmpNum(int a, int b) => _sortAsc ? a.compareTo(b) : b.compareTo(a);
    switch (_sortColumnIndex) {
      case 2: data.sort((a,b)=>cmpNum(a.played, b.played)); break; // P
      case 3: data.sort((a,b)=>cmpNum(a.wins, b.wins));     break; // W
      case 4: data.sort((a,b)=>cmpNum(a.losses, b.losses)); break; // L
      case 5: data.sort((a,b)=>cmpNum(a.points, b.points)); break; // Pts
      default: data.sort((a,b)=>_sortAsc ? a.name.compareTo(b.name) : b.name.compareTo(a.name)); // Naziv
    }

    void setSort(int idx, bool asc) {
      setState(() {
        _sortColumnIndex = idx;
        _sortAsc = asc;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablica poretka'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _discipline,
                    isExpanded: true,
                    items: [for (final d in allDisciplines) DropdownMenuItem(value: d, child: Text(d))],
                    onChanged: (v) => setState(() => _discipline = v!),
                    decoration: const InputDecoration(
                      labelText: 'Disciplina',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Timski prikaz'),
                    value: _isTeam,
                    onChanged: (v) => setState(() => _isTeam = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _StandingsTableMinimal(
                rows: data,
                sortColumnIndex: _sortColumnIndex,
                sortAsc: _sortAsc,
                onSortChanged: setSort,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingsTableMinimal extends StatelessWidget {
  final List<TableRowEntry> rows;
  final int sortColumnIndex;
  final bool sortAsc;
  final void Function(int index, bool asc) onSortChanged;

  const _StandingsTableMinimal({
    required this.rows,
    required this.sortColumnIndex,
    required this.sortAsc,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('Nema podataka za prikaz.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: sortColumnIndex,
        sortAscending: sortAsc,
        headingRowHeight: 48,
        dataRowMinHeight: 44,
        columns: [
          const DataColumn(label: Text('#')),
          DataColumn(
            label: const Text('Naziv'),
            onSort: (i, asc) => onSortChanged(i, asc),
          ),
          DataColumn(
            label: const Text('P'),
            numeric: true,
            onSort: (i, asc) => onSortChanged(i, asc),
          ),
          DataColumn(
            label: const Text('W'),
            numeric: true,
            onSort: (i, asc) => onSortChanged(i, asc),
          ),
          DataColumn(
            label: const Text('L'),
            numeric: true,
            onSort: (i, asc) => onSortChanged(i, asc),
          ),
          DataColumn(
            label: const Text('Pts'),
            numeric: true,
            onSort: (i, asc) => onSortChanged(i, asc),
          ),
        ],
        rows: [
          for (int i = 0; i < rows.length; i++)
            DataRow(cells: [
              DataCell(Text('${i + 1}')),
              DataCell(Text(rows[i].name)),
              DataCell(Text('${rows[i].played}')),
              DataCell(Text('${rows[i].wins}')),
              DataCell(Text('${rows[i].losses}')),
              DataCell(Text('${rows[i].points}')),
            ]),
        ],
      ),
    );
  }
}
