import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Dev login: prijavi se ili kreiraj usera ako ne postoji.
Future<void> runDevSmokeTest() async {
  const email = 'dev@sumfit.dev';
  const password = 'Passw0rd!';
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    // ignore: avoid_print
    print('✅ Signed in as $email');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      // ignore: avoid_print
      print('✅ User created & signed in as $email');
    } else {
      rethrow;
    }
  }

  // Firestore write + read
  final db = FirebaseFirestore.instance;
  final ref = await db.collection('test').add({
    'msg': '🔥 Firestore radi!',
    'uid': FirebaseAuth.instance.currentUser?.uid,
    'ts': FieldValue.serverTimestamp(),
  });
  final snap = await ref.get();
  // ignore: avoid_print
  print('✅ Firestore doc: ${snap.data()}');
}
