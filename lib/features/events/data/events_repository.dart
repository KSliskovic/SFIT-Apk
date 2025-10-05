import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/event.dart';

class EventsRepository {
  static const _key = 'sumfit_events_store_v1';

  final List<EventItem> _items = [];
  final _ctrl = StreamController<List<EventItem>>.broadcast();

  EventsRepository() {
    _restore();
  }

  Stream<List<EventItem>> watchAll() => _ctrl.stream;

  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
    _emit();
    await _persist();
  }

  Future<void> upsert(EventItem e) async {
    final i = _items.indexWhere((x) => x.id == e.id);
    if (i < 0) {
      _items.add(e);
    } else {
      _items[i] = e;
    }
    _emit();
    await _persist();
  }

  void _emit() => _ctrl.add(List.unmodifiable(_items..sort((a,b)=>a.dateTime.compareTo(b.dateTime))));

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      _emit();
      return;
    }
    final list = (jsonDecode(raw) as List?) ?? const [];
    _items
      ..clear()
      ..addAll(list.map((m) => EventItem.fromJson(Map<String, dynamic>.from(m))));
    _emit();
  }
}
