import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/profile.dart';

class ProfileRepository {
  final _db = FirebaseFirestore.instance;

  Future<Profile> load(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) {
      return const Profile(name: '', email: '', role: 'student');
    }
    final data = snap.data()!;
    return Profile.fromJson(data.map((k, v) => MapEntry(k, v)));
  }

  Future<void> save(String uid, Profile p) async {
    await _db.collection('users').doc(uid).set(p.toJson(), SetOptions(merge: true));
  }

  Future<void> clear(String uid) async {
    // po potrebi: await _db.collection('users').doc(uid).delete();
  }
}
