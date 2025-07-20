class UserModel {
  final String id;
  final String email;
  final String name;
  final int age;
  final String? profilePhotoUrl;
  final String company;
  final List<String> foodPreferences;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime lastActive;
  final bool isVerified;
  final double trustScore;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    this.profilePhotoUrl,
    required this.company,
    required this.foodPreferences,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.lastActive,
    this.isVerified = false,
    this.trustScore = 5.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      profilePhotoUrl: json['profilePhotoUrl'],
      company: json['company'] ?? '',
      foodPreferences: List<String>.from(json['foodPreferences'] ?? []),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActive: DateTime.parse(json['lastActive'] ?? DateTime.now().toIso8601String()),
      isVerified: json['isVerified'] ?? false,
      trustScore: json['trustScore']?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'profilePhotoUrl': profilePhotoUrl,
      'company': company,
      'foodPreferences': foodPreferences,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'isVerified': isVerified,
      'trustScore': trustScore,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? profilePhotoUrl,
    String? company,
    List<String>? foodPreferences,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isVerified,
    double? trustScore,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      company: company ?? this.company,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      trustScore: trustScore ?? this.trustScore,
    );
  }
}