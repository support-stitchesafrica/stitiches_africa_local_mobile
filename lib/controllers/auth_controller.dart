import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? user;
  String? token;
  String? error;

  double? latitude;
  double? longitude;
  String? address;

  /// Request Location Permission & Get Coordinates
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    latitude = position.latitude;
    longitude = position.longitude;

    // Reverse geocode to get readable address
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latitude!, longitude!);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      address = "${place.locality}, ${place.country}";
    }
  }

  /// Register User
  Future<Map<String, dynamic>?> register({
    required String fullName,
    required String email,
    required String password,
    required String bvn,
    required String phone,
    String? category,
    String? gender,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // ensure location is set
      if (latitude == null || longitude == null) {
        await _determinePosition();
      }

      final result = await _authService.registerUser(
        fullName: fullName,
        email: email,
        password: password,
        bvn: bvn,
        phone: phone,
        category: category,
        latitude: latitude,
        longitude: longitude,
        address: address,
        gender: gender,
      );

      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register Vendor
  Future<Map<String, dynamic>?> registerVendor({
    required String fullName,
    required String email,
    required String password,
    required String brandName,
    required String phone,
    String? logo,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (latitude == null || longitude == null) {
        await _determinePosition();
      }

      final result = await _authService.registerVendor(
        fullName: fullName,
        email: email,
        password: password,
        brandName: brandName,
        phone: phone,
        logo: logo,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      return result;
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

      return await _authService.verifyBVN(bvn);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login user & Fetch Location
  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);

      token = result['token'];
      user = result['user'];

      await _determinePosition();

      // Save token, user, and location
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token ?? '');
      await prefs.setString('user', jsonEncode(user ?? {}));
      if (latitude != null && longitude != null) {
        await prefs.setDouble('latitude', latitude!);
        await prefs.setDouble('longitude', longitude!);
        await prefs.setString('address', address ?? '');
      }
    } catch (e) {
      error = e.toString();
      print('Login error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
