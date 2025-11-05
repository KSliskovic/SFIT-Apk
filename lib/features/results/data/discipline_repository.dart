import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/discipline.dart';

class DisciplineRepository {
  final _col = FirebaseFirestore.instance.collection('disciplines');

  Stream<List<Discipline>> streamAll() => _col.snapshots().map((snap) => snap.docs
      .map((d) => Discipline.fromJson({...d.data(), 'id': d.id}))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  Future<void> add({required String name, required bool isTeam}) async {
    await _col.add({'name': name.trim(), 'isTeam': isTeam});
  }

  Future<void> update(String id, {required String name, required bool isTeam}) async {
    await _col.doc(id).update({'name': name.trim(), 'isTeam': isTeam});
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
