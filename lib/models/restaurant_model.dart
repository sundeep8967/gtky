import 'dart:math';

class RestaurantModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double averageRating;
  final String? imageUrl;
  final String? phoneNumber;
  final String? website;
  final List<String> cuisineTypes;
  final double rating;
  final int reviewCount;
  final String? photoUrl;
  final bool isPartner;
  final double discountPercentage;
  final Map<String, dynamic>? openingHours;
  final String priceRange; // $, $$, $$$, $$$$
  
  // Partnership specific fields
  final String? ownerName;
  final String? contactPersonName;
  final String? contactPersonPhone;
  final String? contactPersonEmail;
  final DateTime? partnershipStartDate;
  final bool isActive;
  final int maxGroupsPerDay;
  final List<String> specialInstructions;
  final String? bankDetails;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.averageRating = 0.0,
    this.imageUrl,
    this.phoneNumber,
    this.website,
    required this.cuisineTypes,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.photoUrl,
    this.isPartner = false,
    this.discountPercentage = 15.0,
    this.openingHours,
    this.priceRange = '\$\$',
    this.ownerName,
    this.contactPersonName,
    this.contactPersonPhone,
    this.contactPersonEmail,
    this.partnershipStartDate,
    this.isActive = true,
    this.maxGroupsPerDay = 10,
    this.specialInstructions = const [],
    this.bankDetails,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
      phoneNumber: json['phoneNumber'],
      website: json['website'],
      cuisineTypes: List<String>.from(json['cuisineTypes'] ?? []),
      rating: json['rating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      photoUrl: json['photoUrl'],
      isPartner: json['isPartner'] ?? false,
      discountPercentage: json['discountPercentage']?.toDouble() ?? 15.0,
      openingHours: json['openingHours'],
      priceRange: json['priceRange'] ?? '\$\$',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'averageRating': averageRating,
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'website': website,
      'cuisineTypes': cuisineTypes,
      'rating': rating,
      'reviewCount': reviewCount,
      'photoUrl': photoUrl,
      'isPartner': isPartner,
      'discountPercentage': discountPercentage,
      'openingHours': openingHours,
      'priceRange': priceRange,
    };
  }

  double distanceFrom(double userLat, double userLng) {
    // Simple distance calculation (in km)
    const double earthRadius = 6371;
    double dLat = _degreesToRadians(latitude - userLat);
    double dLng = _degreesToRadians(longitude - userLng);
    
    double a = (dLat / 2) * (dLat / 2) +
        _degreesToRadians(userLat) * _degreesToRadians(latitude) *
        (dLng / 2) * (dLng / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  static RestaurantModel fromMap(Map<String, dynamic> map, String id) {
    return RestaurantModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      cuisineTypes: List<String>.from(map['cuisineTypes'] ?? []),
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      priceRange: map['priceRange'] ?? '',
      isPartner: map['isPartner'] ?? false,
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      phoneNumber: map['phoneNumber'],
      website: map['website'],
      openingHours: map['openingHours'] != null 
          ? Map<String, String>.from(map['openingHours'])
          : null,
      photoUrl: map['photoUrl'],
    );
  }
}