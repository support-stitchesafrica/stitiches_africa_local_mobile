import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class UserService {
  final String baseUrl =
      "https://stictches-africa-api-local.vercel.app/api"; // ⬅️ Replace with your backend URL

  /// 🔑 Get token from local storage
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// ✅ Get logged-in user profile
  Future<User?> getProfile() async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse("$baseUrl/user/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('API response data: $data');

      Map<String, dynamic> userData;
      if (data["user"] != null) {
        userData = data["user"];
      } else if (data["data"] != null) {
        userData = data["data"];
      } else {
        userData = data;
      }

      print('User data from API: $userData');
      return User.fromJson(userData);
    } else {
      print('API error response: ${response.body}');
      throw Exception("Failed to load profile");
    }
  }

  /// ✅ Update profile (general info)
  Future<User?> updateProfile(Map<String, dynamic> profileData) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.put(
      Uri.parse("$baseUrl/user/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode(profileData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data["user"]);
    } else {
      print('API error response: ${response.body}');
      throw Exception("Failed to update profile");
    }
  }

  /// ✅ Update location only
  Future<User?> updateLocation(Map<String, dynamic> locationData) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.put(
      Uri.parse("$baseUrl/user/profile/location"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: json.encode(locationData),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data["user"]);
    } else {
      throw Exception("Failed to update location");
    }
  }

  /// ✅ Get my ads
  Future<List<dynamic>> getMyAds() async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse("$baseUrl/user/my-ads"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["ads"];
    } else {
      throw Exception("Failed to fetch ads");
    }
  }

  /// ✅ Logout (clear token)
  Future<void> logout() async {
    final token = await _getToken();
    if (token != null) {
      await http.post(
        Uri.parse("$baseUrl/user/logout"),
        headers: {"Authorization": "Bearer $token"},
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}
