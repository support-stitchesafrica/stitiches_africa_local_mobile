class User {
  final String id;
  final String fullName;
  final String email;
  final String? dob;
  final String? gender;
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
    this.shoppingPreference,
    this.latitude,
    this.longitude,
    this.radius,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"],
      fullName: json["fullName"] ?? "",
      email: json["email"] ?? "",
      dob: json["dob"],
      gender: json["gender"],
      category: json["category"] != null
          ? List<String>.from(json["category"])
          : null,
      style: json["style"] != null
          ? List<String>.from(json["style"])
          : null,
      priceRange: json["priceRange"],
      shoppingPreference: json["shoppingPreference"],
      latitude: json["latitude"]?.toDouble(),
      longitude: json["longitude"]?.toDouble(),
      radius: json["radius"]?.toDouble(),
      address: json["address"],
    );
  }
}
