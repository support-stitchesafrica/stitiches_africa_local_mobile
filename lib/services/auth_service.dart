import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = "http://10.0.2.2:5000/api"; // ✅ Replace with your server URL

  Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String bvn,
    required String dob,
    required String gender,
    required List<String> category,
    required List<String> style,
    required List<String> priceRange,
    required List<String> shoppingPreference,
    required List<String> radius,
    double? latitude,
    double? longitude,
    String? address,
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
        "category": category.join(","),  // ✅ Convert to string if backend expects CSV
        "style": style.join(","),
        "priceRange": priceRange.join(","),
        "shoppingPreference": shoppingPreference.join(","),
        "radius": radius.join(","),
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "dob": dob,
        "gender": gender
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error["message"] ?? "Registration failed");
    }
  }

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
Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid credentials');
    } else {
      throw Exception('Failed to login: ${response.statusCode}');
    }
  }
}
