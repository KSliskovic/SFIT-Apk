// lib/features/auth/data/auth_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/auth_user.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Stream: vraća AuthUser? (null kad korisnik nije prijavljen).
  Stream<AuthUser?> watchAuthState() async* {
    await for (final fbUser in _auth.authStateChanges()) {
      if (fbUser == null) {
        yield null;
      } else {
        yield await _fetchProfile(fbUser.uid);
      }
    }
  }

  /// Trenutni korisnik (učitava i profil iz Firestore-a).
  Future<AuthUser?> getCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    return _fetchProfile(u.uid);
  }

  /// Odjava
  Future<void> signOut() => _auth.signOut();

  /// REGISTRACIJA (email+password) + kreiranje user profila u Firestore
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,       // 'student' | 'organizer'
    String? faculty,
    String? indexNo,
    String? organizerCode,
  }) async {
    // zadrži tvoju staru provjeru organizatorskog koda
    if (role == 'organizer') {
      if (organizerCode == null || organizerCode != 'org123') {
        throw Exception('Pogrešan organizatorski kod');
      }
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      final user = AuthUser(
        uid: uid,
        email: email,
        name: name,
        role: role,
        faculty: faculty,
        indexNo: indexNo,
      );

      // upiši profil u Firestore
      await _db.collection('users').doc(uid).set({
        ...user.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // opcionalno: osvježi displayName na FirebaseAuth useru
      await cred.user!.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e));
    }
  }

  /// LOGIN (email+password)
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // nema potrebe ništa ručno spremati; Firebase drži session
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateAuthError(e));
    }
  }

  // ----------------------------------------
  // Privatno
  // ----------------------------------------

  Future<AuthUser?> _fetchProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) {
      final u = _auth.currentUser;
      if (u == null) return null;
      // ako profil ne postoji, sastavi minimalni iz FirebaseAuth-a
      return AuthUser(
        uid: u.uid,
        email: u.email ?? '',
        name: u.displayName ?? '',
        role: 'user',
      );
    }
    final data = snap.data()!;
    // očekuje se da tvoj AuthUser ima fromJson
    return AuthUser.fromJson({
      ...data,
      // osiguraj uid/email u slučaju da ih nema u dokumentu
      'uid': data['uid'] ?? uid,
      'email': data['email'] ?? (_auth.currentUser?.email ?? ''),
    } as Map<String, dynamic>);
  }

  String _translateAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Nevažeći email.';
      case 'user-disabled':
        return 'Korisnički račun je onemogućen.';
      case 'user-not-found':
        return 'Korisnik ne postoji.';
      case 'wrong-password':
        return 'Pogrešna lozinka.';
      case 'email-already-in-use':
        return 'Email je već u upotrebi.';
      case 'weak-password':
        return 'Lozinka je preslaba.';
      case 'operation-not-allowed':
        return 'Email/Password prijava nije omogućena u konzoli.';
      default:
        return 'Greška pri autentikaciji (${e.code}).';
    }
  }
}
