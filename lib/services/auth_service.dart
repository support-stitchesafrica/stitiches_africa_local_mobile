import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "https://stictches-africa-api-local.vercel.app/api";

  /// Register User
  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String bvn,
    required String phone,
    String? category,
    double? latitude,
    double? longitude,
    String? address,
    String? gender,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "password": password,
        "bvn": bvn,
        "phone": phone,
        "category": category,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "gender": gender,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["message"] ?? "Registration failed");
    }
  }

  /// Register Vendor
  Future<Map<String, dynamic>> registerVendor({
    required String fullName,
    required String email,
    required String password,
    required String brandName,
    required String phone,
    String? logo, // optional, backend expects uploaded file
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register/vendor");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "password": password,
        "brandName": brandName,
        "phone": phone,
        "logo": logo, // optional (backend might handle file upload differently)
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["message"] ?? "Vendor registration failed");
    }
  }

  /// Verify BVN
  Future<Map<String, dynamic>> verifyBVN(String bvn) async {
    final url = Uri.parse("$baseUrl/auth/verify-bvn");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"bvn": bvn}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["message"] ?? "BVN verification failed");
    }
  }

  /// Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid credentials');
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }
}
