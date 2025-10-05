import 'dart:convert';
import '../domain/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersRepository {
  static const _key = 'sumfit_users';

  Future<List<Map<String, dynamic>>> _loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw);
    if (list is List) {
      return list.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<void> _saveRaw(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items));
  }

  Future<List<(AuthUser user, String password)>> getAll() async {
    final raw = await _loadRaw();
    return raw.map<(AuthUser, String)>((m) {
      final user = AuthUser.fromJson(m['user'] as Map<String, dynamic>?)!;
      final pass = (m['password'] as String?) ?? '';
      return (user, pass);
    }).toList();
  }

  Future<(AuthUser user, String password)?> findByEmail(String email) async {
    final all = await getAll();
    for (final it in all) {
      if (it.$1.email.toLowerCase() == email.toLowerCase()) return it;
    }
    return null;
  }

  Future<void> add(AuthUser user, String password) async {
    final raw = await _loadRaw();
    // unique email
    if (raw.any((m) =>
        ((m['user'] as Map?)?['email']?.toString().toLowerCase() ?? '') ==
        user.email.toLowerCase())) {
      throw Exception('Korisnik s ovim emailom već postoji');
    }
    raw.add({'user': user.toJson(), 'password': password});
    await _saveRaw(raw);
  }

  Future<void> update(AuthUser user, {String? password}) async {
    final raw = await _loadRaw();
    final i = raw.indexWhere((m) =>
        ((m['user'] as Map?)?['uid']?.toString() ?? '') == user.uid);
    if (i < 0) return;
    final existing = raw[i];
    raw[i] = {
      'user': user.toJson(),
      'password': password ?? (existing['password'] as String? ?? ''),
    };
    await _saveRaw(raw);
  }
}
