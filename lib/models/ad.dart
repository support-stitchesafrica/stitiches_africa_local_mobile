
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
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

class Ad {
  final String id;
  final String userId;
  final String category;
  final String subCategory;
  final String state;
  final String area;
  final List<String> images;
  final String title;
  final String brand;
  final String? gender;
  final String? collection;
  final String? scent;
  final String? formulation;
  final String? volume;
  final String description;
  final double price;
  final String phone;
  final double? latitude;
  final double? longitude;
  final String address;
  final DateTime createdAt;
  final String? condition; // ✅ Added field
  final User? user;

  Ad({
    required this.id,
    required this.userId,
    required this.category,
    required this.subCategory,
    required this.state,
    required this.area,
    required this.images,
    required this.title,
    required this.brand,
    this.gender,
    this.collection,
    this.scent,
    this.formulation,
    this.volume,
    required this.description,
    required this.price,
    required this.phone,
    this.latitude,
    this.longitude,
    required this.address,
    required this.createdAt,
    this.condition, // ✅ Added to constructor
    this.user,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
        id: json['id'],
        userId: json['userId'],
        category: json['category'],
        subCategory: json['subCategory'],
        state: json['state'],
        area: json['area'],
        images: List<String>.from(json['images'] ?? []),
        title: json['title'],
        brand: json['brand'],
        gender: json['gender'],
        collection: json['collection'],
        scent: json['scent'],
        formulation: json['formulation'],
        volume: json['volume'],
        description: json['description'],
        price: (json['price'] as num).toDouble(),
        phone: json['phone'],
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
        address: json['address'],
        createdAt: DateTime.parse(json['createdAt']),
        condition: json['condition'], // ✅ Parse from API
        user: json['user'] != null ? User.fromJson(json['user']) : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "category": category,
        "subCategory": subCategory,
        "state": state,
        "area": area,
        "images": images,
        "title": title,
        "brand": brand,
        "gender": gender,
        "collection": collection,
        "scent": scent,
        "formulation": formulation,
        "volume": volume,
        "description": description,
        "price": price,
        "phone": phone,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "createdAt": createdAt.toIso8601String(),
        "condition": condition, // ✅ Include in JSON
        "user": user?.toJson(),
      };
}
