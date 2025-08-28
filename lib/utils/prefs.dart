import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static late final SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- token helpers ----
  static String? get token => _prefs.getString('token');
  static Future<void> setToken(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs.remove('token');
    } else {
      await _prefs.setString('token', value);
    }
  }

  // generic helpers (use as needed)
  static String? getString(String key) => _prefs.getString(key);
  static Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  static Future<bool> remove(String key) => _prefs.remove(key);
}
