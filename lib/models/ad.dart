import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

/// -------------------- MODELS --------------------

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;

  User({required this.id, required this.name, required this.email, this.phone});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "email": email,
    "phone": phone,
  };
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] ?? '',
    name: json['categoryName'] ?? json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}

class Ad {
  final String id;
  final String userId;
  final String categoryName;
  final List<String> images;
  final String title;
  final String brand;
  final String? gender;
  final String description;
  final String? promoType;
  final double price;
  final String phone;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime createdAt;
  final User? user;
  final Category? category;

  Ad({
    required this.id,
    required this.userId,
    required this.categoryName,
    required this.images,
    required this.title,
    required this.brand,
    this.gender,
    required this.description,
    this.promoType,
    required this.price,
    required this.phone,
    this.latitude,
    this.longitude,
    this.address,
    required this.createdAt,
    this.user,
    this.category,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
  id: json['id'],
  userId: json['userId'],
  categoryName: json['categoryName'],
  images: List<String>.from(json['images'] ?? []),
  title: json['title'],
  brand: json['brand'],
  gender: json['gender'],
  description: json['description'],
  price: (json['price'] as num).toDouble(),
  phone: json['phone'],
  latitude: json['latitude'] != null
      ? (json['latitude'] as num).toDouble()
      : null,
  longitude: json['longitude'] != null
      ? (json['longitude'] as num).toDouble()
      : null,
  address: json['address'],
  promoType: json['promoType'],
  createdAt: DateTime.parse(json['createdAt']),
  user: json['user'] != null ? User.fromJson(json['user']) : null,
  category: json['category'] != null
      ? Category.fromJson(json['category'])
      : null,
);


  Map<String, dynamic> toJson() => {
    "id": id,
    "userId": userId,
    "categoryName": categoryName,
    "images": images,
    "title": title,
    "brand": brand,
    "gender": gender,
    "description": description,
    "price": price,
    "phone": phone,
    "latitude": latitude,
    "longitude": longitude,
    "address": address,
    "promoType": promoType,
    "createdAt": createdAt.toIso8601String(),
    "user": user?.toJson(),
    "category": category?.toJson(),
  };
}
