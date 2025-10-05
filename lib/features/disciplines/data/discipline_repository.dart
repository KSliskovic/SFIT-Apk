import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/discipline.dart';

class DisciplineRepository {
  static const _storeKey = 'sumfit_disciplines_v1';
  final _ctrl = StreamController<List<Discipline>>.broadcast();
  List<Discipline> _items = [];

  DisciplineRepository() {
    _load();
  }

  Stream<List<Discipline>> watchAll() => _ctrl.stream;

  Future<void> seedIfEmpty() async {
    if (_items.isNotEmpty) return;
    _items = [
      Discipline(id: _id(), name: 'Nogomet 5v5', isTeam: true),
      Discipline(id: _id(), name: 'Košarka', isTeam: true),
      Discipline(id: _id(), name: 'Odbojka', isTeam: true),
      Discipline(id: _id(), name: 'Tenis', isTeam: false),
      Discipline(id: _id(), name: 'Atletika', isTeam: false),
    ];
    _emit();
  }

  void add(String name, {required bool isTeam}) {
    _items = [..._items, Discipline(id: _id(), name: name.trim(), isTeam: isTeam)];
    _emit();
  }

  void update(Discipline d) {
    _items = _items.map((x) => x.id == d.id ? d : x).toList();
    _emit();
  }

  void remove(String id) {
    _items = _items.where((x) => x.id != id).toList();
    _emit();
  }

  // helpers
  String _id() => 'disc_${DateTime.now().microsecondsSinceEpoch}';

  void _emit() {
    _ctrl.add(_items);
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        _items = list.map(Discipline.fromJson).toList();
      } catch (_) {}
    }
    _emit();
  }
}
