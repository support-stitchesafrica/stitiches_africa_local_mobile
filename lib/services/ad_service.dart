import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ad.dart';

class AdService {
  final String baseUrl;
  final String? token;

  AdService({required this.baseUrl, this.token});

  Map<String, String> get headers {
    final h = {"Content-Type": "application/json"};
    if (token != null) h["Authorization"] = "Bearer $token";
    return h;
  }

  Future<List<Ad>> getAllAds() async {
    final res = await http.get(Uri.parse("$baseUrl/sell"), headers: headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Ad.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch ads");
  }

  Future<Ad> getAdById(String id) async {
    final res = await http.get(Uri.parse("$baseUrl/sell/$id"), headers: headers);
    if (res.statusCode == 200) {
      return Ad.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to fetch ad");
  }

  Future<List<Ad>> getMyAds() async {
    final res = await http.get(Uri.parse("$baseUrl/sell/my"), headers: headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Ad.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch my ads");
  }

  Future<Ad> createAd(Ad ad) async {
    final res = await http.post(
      Uri.parse("$baseUrl/sell"),
      headers: headers,
      body: jsonEncode(ad.toJson()),
    );
    if (res.statusCode == 201) {
      return Ad.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to create ad: ${res.body}");
  }

  Future<Ad> updateAd(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/sell/$id"),
      headers: headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return Ad.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to update ad");
  }

  Future<void> deleteAd(String id) async {
    final res = await http.delete(Uri.parse("$baseUrl/sell/$id"), headers: headers);
    if (res.statusCode != 200) {
      throw Exception("Failed to delete ad");
    }
  }

  /// ✅ Get brands by location (No radius)
  Future<List<String>> getBrandsByLocation(double lat, double lng) async {
    final res = await http.get(
      Uri.parse("$baseUrl/sell/brands/location?latitude=$lat&longitude=$lng"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return List<String>.from(data);
      }
      if (data is Map && data.containsKey("brands")) {
        return List<String>.from(data["brands"]);
      }
      return [];
    }
    throw Exception("Failed to fetch brands by location");
  }

  /// ✅ Get listings by brand (No radius)
  Future<List<Ad>> getListingsByBrand(String brand, double lat, double lng) async {
    final res = await http.get(
      Uri.parse("$baseUrl/sell/brands/$brand/location?latitude=$lat&longitude=$lng"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is List) {
        return data.map((e) => Ad.fromJson(e)).toList();
      }
      if (data is Map && data.containsKey("ads")) {
        return (data["ads"] as List).map((e) => Ad.fromJson(e)).toList();
      }
      return [];
    }
    throw Exception("Failed to fetch listings by brand");
  }
}
