import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/auth_user.dart';
import 'users_repository.dart';

class AuthRepository {
  static const _currentKey = 'sumfit_auth_user';
  final UsersRepository users;

  AuthRepository(this.users);

  Future<AuthUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_currentKey);
    if (raw == null) return null;
    return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>?);
  }

  Future<void> _setCurrent(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentKey, jsonEncode(user.toJson()));
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentKey);
  }

  /// REGISTRACIJA
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,       // 'student' | 'organizer'
    String? faculty,
    String? indexNo,
    String? organizerCode,
  }) async {
    if (role == 'organizer') {
      if (organizerCode == null || organizerCode != 'org123') {
        throw Exception('Pogrešan organizatorski kod');
      }
    }
    final user = AuthUser(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      role: role,
      faculty: faculty,
      indexNo: indexNo,
    );
    await users.add(user, password);
    await _setCurrent(user); // auto-login nakon registracije
  }

  /// LOGIN
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final rec = await users.findByEmail(email);
    if (rec == null) {
      throw Exception('Korisnik ne postoji');
    }
    if (rec.$2 != password) {
      throw Exception('Pogrešna lozinka');
    }
    await _setCurrent(rec.$1);
  }
}
