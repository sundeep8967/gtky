import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dining_plan_model.dart';
import '../models/restaurant_model.dart';
import '../models/rating_model.dart';

class AdvancedMatchingService {
  static final AdvancedMatchingService _instance = AdvancedMatchingService._internal();
  factory AdvancedMatchingService() => _instance;
  AdvancedMatchingService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User preference learning
  Future<Map<String, double>> analyzeUserPreferences(String userId) async {
    try {
      final preferences = <String, double>{};

      // Analyze past dining plans
      final plansQuery = await _db.collection('dining_plans')
          .where('memberIds', arrayContains: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final restaurantIds = <String>[];
      final timePreferences = <int>[];
      final groupSizes = <int>[];

      for (var doc in plansQuery.docs) {
        final plan = DiningPlanModel.fromJson(doc.data());
        restaurantIds.add(plan.restaurantId);
        timePreferences.add(plan.plannedTime.hour);
        groupSizes.add(plan.memberIds.length);
      }

      // Analyze cuisine preferences from restaurants
      final cuisinePreferences = <String, int>{};
      for (String restaurantId in restaurantIds) {
        final restaurantDoc = await _db.collection('restaurants').doc(restaurantId).get();
        if (restaurantDoc.exists) {
          final restaurant = RestaurantModel.fromJson(restaurantDoc.data()!);
          for (String cuisine in restaurant.cuisineTypes) {
            cuisinePreferences[cuisine] = (cuisinePreferences[cuisine] ?? 0) + 1;
          }
        }
      }

      // Calculate preference scores (0.0 to 1.0)
      final totalPlans = plansQuery.docs.length;
      if (totalPlans > 0) {
        // Cuisine preferences
        cuisinePreferences.forEach((cuisine, count) {
          preferences['cuisine_$cuisine'] = count / totalPlans;
        });

        // Time preferences
        final timeGroups = <String, int>{
          'morning': 0,
          'lunch': 0,
          'evening': 0,
          'night': 0,
        };

        for (int hour in timePreferences) {
          if (hour >= 6 && hour < 11) timeGroups['morning'] = timeGroups['morning']! + 1;
          else if (hour >= 11 && hour < 16) timeGroups['lunch'] = timeGroups['lunch']! + 1;
          else if (hour >= 16 && hour < 21) timeGroups['evening'] = timeGroups['evening']! + 1;
          else timeGroups['night'] = timeGroups['night']! + 1;
        }

        timeGroups.forEach((timeSlot, count) {
          preferences['time_$timeSlot'] = count / totalPlans;
        });

        // Group size preferences
        final avgGroupSize = groupSizes.reduce((a, b) => a + b) / groupSizes.length;
        preferences['preferred_group_size'] = avgGroupSize / 4.0; // Normalize to 0-1
      }

      // Analyze ratings to understand quality preferences
      final ratingsQuery = await _db.collection('ratings')
          .where('raterId', isEqualTo: userId)
          .get();

      if (ratingsQuery.docs.isNotEmpty) {
        double totalRating = 0;
        int ratingCount = 0;
        
        for (var doc in ratingsQuery.docs) {
          final rating = RatingModel.fromJson(doc.data());
          totalRating += rating.rating;
          ratingCount++;
        }

        preferences['quality_threshold'] = (totalRating / ratingCount) / 5.0; // Normalize to 0-1
      }

      return preferences;
    } catch (e) {
      print('Error analyzing user preferences: $e');
      return {};
    }
  }

  // Geographic optimization
  Future<List<DiningPlanModel>> getOptimizedPlans({
    required String userId,
    required double userLat,
    required double userLng,
    double maxDistance = 10.0, // km
    int limit = 20,
  }) async {
    try {
      // Get all open plans
      final plansQuery = await _db.collection('dining_plans')
          .where('status', isEqualTo: 'open')
          .where('memberIds', whereNotIn: [userId]) // Exclude user's own plans
          .limit(100) // Get more to filter by distance
          .get();

      final plans = <DiningPlanModel>[];
      final restaurantCache = <String, RestaurantModel>{};

      for (var doc in plansQuery.docs) {
        final plan = DiningPlanModel.fromJson(doc.data());
        
        // Skip if user is already a member
        if (plan.memberIds.contains(userId)) continue;

        // Get restaurant location
        RestaurantModel? restaurant = restaurantCache[plan.restaurantId];
        if (restaurant == null) {
          final restaurantDoc = await _db.collection('restaurants').doc(plan.restaurantId).get();
          if (restaurantDoc.exists) {
            restaurant = RestaurantModel.fromJson(restaurantDoc.data()!);
            restaurantCache[plan.restaurantId] = restaurant;
          }
        }

        if (restaurant != null) {
          // Calculate distance
          final distance = _calculateDistance(
            userLat, userLng,
            restaurant.latitude, restaurant.longitude,
          );

          if (distance <= maxDistance) {
            plans.add(plan);
          }
        }
      }

      // Sort by distance and other factors
      plans.sort((a, b) {
        final restaurantA = restaurantCache[a.restaurantId]!;
        final restaurantB = restaurantCache[b.restaurantId]!;
        
        final distanceA = _calculateDistance(userLat, userLng, restaurantA.latitude, restaurantA.longitude);
        final distanceB = _calculateDistance(userLat, userLng, restaurantB.latitude, restaurantB.longitude);
        
        return distanceA.compareTo(distanceB);
      });

      return plans.take(limit).toList();
    } catch (e) {
      print('Error getting optimized plans: $e');
      return [];
    }
  }

  // Success rate optimization
  Future<double> calculateMatchSuccessRate(String userId) async {
    try {
      final plansQuery = await _db.collection('dining_plans')
          .where('memberIds', arrayContains: userId)
          .get();

      if (plansQuery.docs.isEmpty) return 0.5; // Default for new users

      int totalPlans = 0;
      int successfulPlans = 0;

      for (var doc in plansQuery.docs) {
        final plan = DiningPlanModel.fromJson(doc.data());
        totalPlans++;
        
        if (plan.status == PlanStatus.completed) {
          successfulPlans++;
        }
      }

      return successfulPlans / totalPlans;
    } catch (e) {
      print('Error calculating success rate: $e');
      return 0.5;
    }
  }

  // Personalized restaurant recommendations
  Future<List<RestaurantModel>> getPersonalizedRecommendations({
    required String userId,
    required double userLat,
    required double userLng,
    int limit = 10,
  }) async {
    try {
      final userPreferences = await analyzeUserPreferences(userId);
      
      // Get all restaurants
      final restaurantsQuery = await _db.collection('restaurants')
          .where('isPartner', isEqualTo: true)
          .get();

      final scoredRestaurants = <MapEntry<RestaurantModel, double>>[];

      for (var doc in restaurantsQuery.docs) {
        final restaurant = RestaurantModel.fromJson(doc.data());
        final score = _calculateRestaurantScore(restaurant, userPreferences, userLat, userLng);
        scoredRestaurants.add(MapEntry(restaurant, score));
      }

      // Sort by score (highest first)
      scoredRestaurants.sort((a, b) => b.value.compareTo(a.value));

      return scoredRestaurants.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      return [];
    }
  }

  // Optimal timing recommendations
  Future<List<DateTime>> getOptimalTimings({
    required String userId,
    required String restaurantId,
    required DateTime targetDate,
  }) async {
    try {
      final userPreferences = await analyzeUserPreferences(userId);
      final recommendations = <DateTime>[];

      // Get user's preferred time slots
      final timePreferences = <String, double>{
        'morning': userPreferences['time_morning'] ?? 0.0,
        'lunch': userPreferences['time_lunch'] ?? 0.3,
        'evening': userPreferences['time_evening'] ?? 0.5,
        'night': userPreferences['time_night'] ?? 0.2,
      };

      // Generate time slots for the target date
      final baseDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
      
      // Lunch slots (11 AM - 3 PM)
      for (int hour = 11; hour <= 15; hour++) {
        for (int minute in [0, 30]) {
          final time = baseDate.add(Duration(hours: hour, minutes: minute));
          if (time.isAfter(DateTime.now().add(const Duration(minutes: 30)))) {
            recommendations.add(time);
          }
        }
      }

      // Evening slots (6 PM - 9 PM)
      for (int hour = 18; hour <= 21; hour++) {
        for (int minute in [0, 30]) {
          final time = baseDate.add(Duration(hours: hour, minutes: minute));
          if (time.isAfter(DateTime.now().add(const Duration(minutes: 30)))) {
            recommendations.add(time);
          }
        }
      }

      // Sort by user preference and availability
      recommendations.sort((a, b) {
        final scoreA = _getTimeSlotScore(a, timePreferences);
        final scoreB = _getTimeSlotScore(b, timePreferences);
        return scoreB.compareTo(scoreA);
      });

      return recommendations.take(6).toList(); // Return top 6 recommendations
    } catch (e) {
      print('Error getting optimal timings: $e');
      return [];
    }
  }

  // Cuisine preference matching
  Future<List<String>> getMatchingCuisines(String userId) async {
    try {
      final userPreferences = await analyzeUserPreferences(userId);
      
      final cuisineScores = <MapEntry<String, double>>[];
      
      userPreferences.forEach((key, value) {
        if (key.startsWith('cuisine_')) {
          final cuisine = key.substring(8); // Remove 'cuisine_' prefix
          cuisineScores.add(MapEntry(cuisine, value));
        }
      });

      // Sort by preference score
      cuisineScores.sort((a, b) => b.value.compareTo(a.value));
      
      return cuisineScores.map((entry) => entry.key).toList();
    } catch (e) {
      print('Error getting matching cuisines: $e');
      return [];
    }
  }

  // Private helper methods
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Haversine formula for calculating distance between two points
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  double _calculateRestaurantScore(
    RestaurantModel restaurant,
    Map<String, double> userPreferences,
    double userLat,
    double userLng,
  ) {
    double score = 0.0;

    // Cuisine preference score (40% weight)
    double cuisineScore = 0.0;
    for (String cuisine in restaurant.cuisineTypes) {
      cuisineScore += userPreferences['cuisine_$cuisine'] ?? 0.0;
    }
    score += (cuisineScore / restaurant.cuisineTypes.length) * 0.4;

    // Distance score (30% weight) - closer is better
    final distance = _calculateDistance(userLat, userLng, restaurant.latitude, restaurant.longitude);
    final distanceScore = (10 - distance.clamp(0, 10)) / 10; // Normalize to 0-1
    score += distanceScore * 0.3;

    // Rating score (20% weight)
    final ratingScore = restaurant.averageRating / 5.0;
    score += ratingScore * 0.2;

    // Discount score (10% weight)
    final discountScore = restaurant.discountPercentage / 100.0;
    score += discountScore * 0.1;

    return score;
  }

  double _getTimeSlotScore(DateTime time, Map<String, double> timePreferences) {
    final hour = time.hour;
    
    if (hour >= 6 && hour < 11) return timePreferences['morning'] ?? 0.0;
    if (hour >= 11 && hour < 16) return timePreferences['lunch'] ?? 0.0;
    if (hour >= 16 && hour < 21) return timePreferences['evening'] ?? 0.0;
    return timePreferences['night'] ?? 0.0;
  }
}