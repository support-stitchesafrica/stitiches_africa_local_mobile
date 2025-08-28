import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  // ---- user data helpers ----
  static Map<String, dynamic>? get userData {
    final userString = _prefs.getString('user');
    if (userString != null && userString.isNotEmpty) {
      try {
        return jsonDecode(userString);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> setUserData(Map<String, dynamic>? userData) async {
    if (userData == null) {
      await _prefs.remove('user');
    } else {
      await _prefs.setString('user', jsonEncode(userData));
    }
  }

  // ---- location helpers ----
  static double? get latitude => _prefs.getDouble('latitude');
  static double? get longitude => _prefs.getDouble('longitude');
  static String? get address => _prefs.getString('address');

  static Future<void> setLocation({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    if (latitude != null) await _prefs.setDouble('latitude', latitude);
    if (longitude != null) await _prefs.setDouble('longitude', longitude);
    if (address != null) await _prefs.setString('address', address);
  }

  // ---- logout helper ----
  static Future<void> clearAll() async {
    await _prefs.clear();
  }

  // generic helpers (use as needed)
  static String? getString(String key) => _prefs.getString(key);
  static Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  static Future<bool> remove(String key) => _prefs.remove(key);
}
