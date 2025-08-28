class User {
  final String id;
  final String fullName;
  final String email;
  final String? dob;
  final String? gender;
  final String? image;
  final List<String>? category;
  final List<String>? style;
  final String? priceRange;
  final String? shoppingPreference;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final String? address;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.dob,
    this.gender,
    this.category,
    this.style,
    this.priceRange,
    this.image,
    this.shoppingPreference,
    this.latitude,
    this.longitude,
    this.radius,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper function to convert data to List<String>
    List<String>? parseStringList(dynamic data) {
      if (data == null) return null;
      if (data is List) {
        return data.map((item) => item.toString()).toList();
      }
      if (data is String) {
        if (data.isEmpty) return null;
        return data.split(',').map((item) => item.trim()).toList();
      }
      return null;
    }

    return User(
      id: json["id"]?.toString() ?? "",
      fullName: json["fullName"]?.toString() ?? "",
      email: json["email"]?.toString() ?? "",
      dob: json["dob"]?.toString(),
      gender: json["gender"]?.toString(),
      image: json['image']?.toString(),
      category: parseStringList(json["category"]),
      style: parseStringList(json["style"]),
      priceRange: json["priceRange"]?.toString(),
      shoppingPreference: json["shoppingPreference"]?.toString(),
      latitude: json["latitude"] != null
          ? double.tryParse(json["latitude"].toString())
          : null,
      longitude: json["longitude"] != null
          ? double.tryParse(json["longitude"].toString())
          : null,
      radius: json["radius"] != null
          ? double.tryParse(json["radius"].toString())
          : null,
      address: json["address"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "fullName": fullName,
      "email": email,
      "dob": dob,
      "gender": gender,
      "image": image,
      "category": category,
      "style": style,
      "priceRange": priceRange,
      "shoppingPreference": shoppingPreference,
      "latitude": latitude,
      "longitude": longitude,
      "radius": radius,
      "address": address,
    };
  }
}
