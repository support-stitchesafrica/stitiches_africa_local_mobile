import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
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

  /// Get all ads
  Future<List<Ad>> getAllAds() async {
    final res = await http.get(Uri.parse("$baseUrl/ads"), headers: headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Ad.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch ads");
  }

  /// Get ad by ID
  Future<Ad> getAdById(String id) async {
    final res = await http.get(Uri.parse("$baseUrl/ads/$id"), headers: headers);
    if (res.statusCode == 200) {
      return Ad.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to fetch ad");
  }

  /// Get my ads
  Future<List<Ad>> getMyAds() async {
    final res = await http.get(Uri.parse("$baseUrl/ads/my"), headers: headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Ad.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch my ads");
  }

  /// Create ad
  Future<Ad> createAd(Map<String, dynamic> fields, List<File> images) async {
    if (token == null) throw Exception("User not logged in");

    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/ads"));
    request.headers['Authorization'] = 'Bearer $token';

    // add fields
    fields.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    // add images
    for (var file in images) {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 201) {
      return Ad.fromJson(jsonDecode(res.body));
    } else {
      print(res.body);
      throw Exception("Failed to create ad: ${res.statusCode} ${res.body}");
    }
  }

  /// Update ad
  Future<Ad> updateAd(String id, Map<String, dynamic> data, {List<File>? images}) async {
    if (token == null) throw Exception("User not logged in");

    var request = http.MultipartRequest("PUT", Uri.parse("$baseUrl/ads/$id"));
    request.headers['Authorization'] = 'Bearer $token';

    data.forEach((key, value) {
      if (value != null) request.fields[key] = value.toString();
    });

    if (images != null) {
      for (var file in images) {
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          file.path,
          contentType: MediaType.parse(mimeType),
        ));
      }
    }

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) {
      return Ad.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to update ad: ${res.body}");
  }

  /// Delete ad
  Future<void> deleteAd(String id) async {
    final res = await http.delete(Uri.parse("$baseUrl/ads/$id"), headers: headers);
    if (res.statusCode != 200) {
      throw Exception("Failed to delete ad");
    }
  }

  /// Get ads by location
  Future<List<Ad>> getAdsByLocation(double lat, double lng, {double radius = 5}) async {
    final res = await http.get(
      Uri.parse("$baseUrl/ads/location?latitude=$lat&longitude=$lng&radius=$radius"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Ad.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch ads by location");
  }

  /// Get brands by location
  Future<List<Map<String, dynamic>>> getBrandsByLocation(double lat, double lng, {double radius = 5}) async {
    final res = await http.get(
      Uri.parse("$baseUrl/ads/brands/location?latitude=$lat&longitude=$lng&radius=$radius"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data["brands"]);
    }
    throw Exception("Failed to fetch brands by location");
  }

  /// Get listings by brand
  Future<List<Ad>> getListingsByBrand(String brand, double lat, double lng, {double radius = 5}) async {
    final res = await http.get(
      Uri.parse("$baseUrl/ads/brands/$brand/location?latitude=$lat&longitude=$lng&radius=$radius"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data["listings"] as List).map((e) => Ad.fromJson(e)).toList();
    }
    throw Exception("Failed to fetch listings by brand");
  }

  /// Get listing by ID + location
  Future<Ad> getListingByIdAndLocation(String id, double lat, double lng, {double radius = 5}) async {
    final res = await http.get(
      Uri.parse("$baseUrl/ads/$id/location?latitude=$lat&longitude=$lng&radius=$radius"),
      headers: headers,
    );
    if (res.statusCode == 200) {
      return Ad.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to fetch listing by ID & location");
  }
}