import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/profile.dart';

class ProfileRepository {
  static const _key = 'sumfit_profile_v1';

  Future<Profile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      // default profil
      return const Profile(name: '', email: '', role: 'student');
    }
    return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(Profile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(p.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
