import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  // Private loading flag
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // User data
  Map<String, dynamic>? user;
  String? token;
  String? error;

  /// Register a new user
  Future<Map<String, dynamic>?> register({
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
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _authService.registerUser(
        fullName: fullName,
        email: email,
        password: password,
        bvn: bvn,
        category: category,
        style: style,
        priceRange: priceRange,
        shoppingPreference: shoppingPreference,
        radius: radius,
        latitude: latitude,
        longitude: longitude,
        address: address,
        dob: dob,
        gender: gender
      );

      return result;
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify BVN
  Future<Map<String, dynamic>?> verifyBVN(String bvn) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _authService.verifyBVN(bvn);
      return result;
    } catch (e) {
      throw Exception(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login user
 Future<void> login({required String email, required String password}) async {
  _isLoading = true;
  error = null;
  notifyListeners();

  try {
    final result = await _authService.login(email: email, password: password);

    token = result['token'];
    user = result['user'];

    // ✅ Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token ?? '');
    await prefs.setString('user', user != null ? user.toString() : '');

    // ✅ Print the response for debugging
    print('Login successful: $result');
    print('Saved token: $token');

  } catch (e) {
    error = e.toString();
    print('Login error: $error');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}
