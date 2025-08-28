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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
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
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latitude!,
      longitude!,
    );
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      address = "${place.locality}, ${place.country}";
    }
  }

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
        gender: gender,
      );

      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> verifyBVN(String bvn) async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _authService.verifyBVN(bvn);
      return result;
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

      // Get and store user location
      await _determinePosition();

      // Save token, user, and location to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token ?? '');
      await prefs.setString('user', user != null ? jsonEncode(user) : '');
      if (latitude != null && longitude != null) {
        await prefs.setDouble('latitude', latitude!);
        await prefs.setDouble('longitude', longitude!);
        await prefs.setString('address', address ?? '');
      }

      print('Login successful: $result');
      print('Saved token: $token');
      print('User Location: $latitude, $longitude ($address)');
    } catch (e) {
      error = e.toString();
      print('Login error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
