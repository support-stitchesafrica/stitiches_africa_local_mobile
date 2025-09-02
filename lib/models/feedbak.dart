class AdRating {
  final String id;
  final int rating;
  final String userName;
  final String? brandName;
  final String? logo;

  AdRating({
    required this.id,
    required this.rating,
    required this.userName,
    this.brandName,
    this.logo,
  });

  factory AdRating.fromJson(Map<String, dynamic> json) {
    return AdRating(
      id: json['id'],
      rating: json['rating'],
      userName: json['user']['fullName'] ?? '',
      brandName: json['user']['brandName'],
      logo: json['user']['logo'],
    );
  }
}

class AdComment {
  final String id;
  final String content;
  final String? brandName;
  final String? logo;

  AdComment({
    required this.id,
    required this.content,
    this.brandName,
    this.logo,
  });

  factory AdComment.fromJson(Map<String, dynamic> json) {
    return AdComment(
      id: json['id'],
      content: json['content'],
      brandName: json['user']['brandName'],
      logo: json['user']['logo'],
    );
  }
}

class AdFeedback {
  final String adId;
  final int ratingCount;
  final double averageRating;
  final List<AdRating> ratings;
  final List<AdComment> comments;

  AdFeedback({
    required this.adId,
    required this.ratingCount,
    required this.averageRating,
    required this.ratings,
    required this.comments,
  });

  factory AdFeedback.fromJson(Map<String, dynamic> json) {
    return AdFeedback(
      adId: json['adId'],
      ratingCount: json['ratingCount'],
      averageRating: (json['averageRating'] as num).toDouble(),
      ratings: (json['ratings'] as List)
          .map((r) => AdRating.fromJson(r))
          .toList(),
      comments: (json['comments'] as List)
          .map((c) => AdComment.fromJson(c))
          .toList(),
    );
  }
}
