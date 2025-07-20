class RatingModel {
  final String id;
  final String matchId;
  final String raterId;
  final String? ratedUserId; // null for restaurant ratings
  final String? restaurantId; // null for user ratings
  final double rating; // 1-5 stars
  final String? comment;
  final DateTime createdAt;
  final List<String> tags; // e.g., ['friendly', 'punctual', 'good_food']

  RatingModel({
    required this.id,
    required this.matchId,
    required this.raterId,
    this.ratedUserId,
    this.restaurantId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.tags = const [],
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] ?? '',
      matchId: json['matchId'] ?? '',
      raterId: json['raterId'] ?? '',
      ratedUserId: json['ratedUserId'],
      restaurantId: json['restaurantId'],
      rating: json['rating']?.toDouble() ?? 0.0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'raterId': raterId,
      'ratedUserId': ratedUserId,
      'restaurantId': restaurantId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  bool get isUserRating => ratedUserId != null;
  bool get isRestaurantRating => restaurantId != null;
}