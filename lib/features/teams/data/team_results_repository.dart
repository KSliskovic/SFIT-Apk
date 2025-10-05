import 'dart:async';
import '../../teams/domain/team_result_entry.dart';

class TeamResultsRepository {
  final _controller = StreamController<List<TeamResultEntry>>.broadcast();
  List<TeamResultEntry> _items = [];

  TeamResultsRepository() {
    // seed primjer
    _items = [
      TeamResultEntry(id: 'tr_1', eventId: 'ev_001', discipline: 'Nogomet 5v5', teamId: 'tm_1', value: 3, unit: 'pts'),
      TeamResultEntry(id: 'tr_2', eventId: 'ev_001', discipline: 'Nogomet 5v5', teamId: 'tm_2', value: 1, unit: 'pts'),
    ];
    _emit();
  }

  Stream<List<TeamResultEntry>> watchAll() => _controller.stream;

  List<TeamResultEntry> forEventDiscipline(String eventId, String discipline) {
    final list = _items.where((r) => r.eventId == eventId && r.discipline == discipline).toList();
    // default: veće je bolje za bodove; ovo možemo parametrizirati po disciplini
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  void add(TeamResultEntry e) { _items = [..._items, e]; _emit(); }
  void update(TeamResultEntry e) { _items = _items.map((x) => x.id == e.id ? e : x).toList(); _emit(); }
  void delete(String id) { _items = _items.where((x) => x.id != id).toList(); _emit(); }

  void _emit() => _controller.add(List.unmodifiable(_items));
  void dispose() => _controller.close();
}
