import 'package:shared_preferences/shared_preferences.dart';

class SessionRepository {
  static const _sessionKey = 'sumfit_session_email_v1';

  Future<void> setCurrentEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, email);
  }

  Future<String?> getCurrentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
