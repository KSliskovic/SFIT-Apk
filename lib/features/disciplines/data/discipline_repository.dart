import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/discipline.dart';

class DisciplineRepository {
  final _col = FirebaseFirestore.instance.collection('disciplines');

  Stream<List<Discipline>> watchAll() {
    return _col.snapshots().map((s) => s.docs.map((d) {
      final data = d.data();
      return Discipline.fromJson({...data, 'id': d.id} as Map<String, dynamic>);
    }).toList());
  }

  Future<void> add(String name, {required bool isTeam}) async {
    await _col.add({'name': name.trim(), 'isTeam': isTeam});
  }

  Future<void> update(Discipline d) async {
    await _col.doc(d.id).set(d.toJson()..remove('id'), SetOptions(merge: true));
  }

  Future<void> remove(String id) async {
    await _col.doc(id).delete();
  }
}
