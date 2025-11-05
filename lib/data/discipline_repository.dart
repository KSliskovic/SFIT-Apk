import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/discipline.dart';

class DisciplineRepository {
  final _col = FirebaseFirestore.instance.collection('disciplines');

  /// Stabilno sortiranje po nameLower (ako neki dokumenti nemaju polje, i dalje radi).
  Stream<List<Discipline>> streamAll() => _col
      .orderBy('nameLower')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => Discipline.fromJson({...d.data(), 'id': d.id}))
          .toList());

  Future<void> add({required String name, required bool isTeam}) async {
    final n = name.trim();
    if (n.isEmpty) return;
    await _col.add({
      'name': n,
      'isTeam': isTeam,
      'nameLower': n.toLowerCase(),
    });
  }

  Future<void> update(String id, {required String name, required bool isTeam}) async {
    final n = name.trim();
    if (n.isEmpty) return;
    await _col.doc(id).update({
      'name': n,
      'isTeam': isTeam,
      'nameLower': n.toLowerCase(),
    });
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}

/// Riverpod provider za repo
final disciplineRepositoryProvider = Provider<DisciplineRepository>((ref) {
  return DisciplineRepository();
});
