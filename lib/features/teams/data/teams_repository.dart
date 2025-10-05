import 'dart:async';
import '../../teams/domain/team.dart';

class TeamsRepository {
  final _controller = StreamController<List<Team>>.broadcast();
  List<Team> _items = [];

  TeamsRepository() {
    // seed demo
    _items = [
      Team(id: 'tm_1', eventId: 'ev_001', name: 'FER Zagreb A', members: ['Ana', 'Iva', 'Marta', 'Lea', 'Mia']),
      Team(id: 'tm_2', eventId: 'ev_001', name: 'FSB Zagreb', members: ['Marko', 'Ivan', 'Petar', 'Luka', 'Nikola']),
    ];
    _emit();
  }

  Stream<List<Team>> watchAll() => _controller.stream;

  List<Team> forEvent(String eventId) =>
      _items.where((t) => t.eventId == eventId).toList();

  Team? byId(String id) => _items.firstWhere((t) => t.id == id, orElse: () => null as Team);

  void add(Team t) { _items = [..._items, t]; _emit(); }

  void update(Team t) { _items = _items.map((x) => x.id == t.id ? t : x).toList(); _emit(); }

  void delete(String id) { _items = _items.where((t) => t.id != id).toList(); _emit(); }

  void _emit() => _controller.add(List.unmodifiable(_items));

  void dispose() => _controller.close();
}
