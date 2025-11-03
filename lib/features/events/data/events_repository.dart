import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/event.dart';

class EventsRepository {
  final _col = FirebaseFirestore.instance.collection('events');

  Stream<List<EventItem>> watchAll() {
    return _col.orderBy('startAt', descending: false).snapshots().map(
          (snap) => snap.docs.map((d) {
        final data = d.data();
        return EventItem.fromJson({
          ...data,
          'id': d.id,
        } as Map<String, dynamic>);
      }).toList(),
    );
  }

  Future<void> add(EventItem item) async {
    final data = item.toJson()..remove('id');
    await _col.add(data);
  }

  Future<void> upsert(EventItem item) async {
    if (item.id == null || item.id!.isEmpty) {
      await add(item);
    } else {
      final data = item.toJson()..remove('id');
      await _col.doc(item.id).set(data, SetOptions(merge: true));
    }
  }

  Future<void> remove(String id) async {
    await _col.doc(id).delete();
  }
}
