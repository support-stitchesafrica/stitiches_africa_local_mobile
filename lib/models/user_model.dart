class User {
  final String id;
  final String fullName;
  final String email;
  final String? gender;
  final String? image;
  final String? phone;
  final String? userType;
  final String? logo;
  final List<String>? category;
  final double? latitude;
  final double? longitude;
  final String? address;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.gender,
    this.image,
    this.phone,
    this.userType,
    this.logo,
    this.category,
    this.latitude,
    this.longitude,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper to parse category into List<String>
    List<String>? parseStringList(dynamic data) {
      if (data == null) return null;
      if (data is List) {
        return data.map((item) => item.toString()).toList();
      }
      if (data is String) {
        if (data.isEmpty) return null;
        return data.split(',').map((e) => e.trim()).toList();
      }
      return null;
    }

    return User(
      id: json["id"]?.toString() ?? "",
      fullName: json["fullName"]?.toString() ?? "",
      email: json["email"]?.toString() ?? "",
      gender: json["gender"]?.toString(),
      image: json["image"]?.toString(),
      phone: json["phone"]?.toString(),
      userType: json["userType"]?.toString(),
      logo: json["logo"]?.toString(),
      category: parseStringList(json["category"]),
      latitude: json["latitude"] != null
          ? double.tryParse(json["latitude"].toString())
          : null,
      longitude: json["longitude"] != null
          ? double.tryParse(json["longitude"].toString())
          : null,
      address: json["address"]?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "fullName": fullName,
      "email": email,
      "gender": gender,
      "image": image,
      "phone": phone,
      "userType": userType,
      "logo": logo,
      "category": category,
      "latitude": latitude,
      "longitude": longitude,
      "address": address,
    };
  }
}
