import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant_model.dart';
import 'location_service.dart';

class RestaurantService {
  static final RestaurantService _instance = RestaurantService._internal();
  factory RestaurantService() => _instance;
  RestaurantService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  // Get partner restaurants near user location
  Future<List<RestaurantModel>> getPartnerRestaurantsNearby({
    double? latitude,
    double? longitude,
    double radiusKm = 10.0,
  }) async {
    try {
      Position? userPosition;
      
      if (latitude == null || longitude == null) {
        userPosition = await _locationService.getCurrentPosition();
        if (userPosition == null) {
          throw Exception('Unable to get user location');
        }
        latitude = userPosition.latitude;
        longitude = userPosition.longitude;
      }

      // Query partner restaurants
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('isPartner', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      List<RestaurantModel> restaurants = [];
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          RestaurantModel restaurant = RestaurantModel.fromJson(data);
          
          // Calculate distance and filter by radius
          double distance = restaurant.distanceFrom(latitude!, longitude!);
          if (distance <= radiusKm) {
            restaurants.add(restaurant);
          }
        } catch (e) {
          print('Error parsing restaurant ${doc.id}: $e');
        }
      }

      // Sort by distance
      restaurants.sort((a, b) => 
          a.distanceFrom(latitude!, longitude!).compareTo(
              b.distanceFrom(latitude!, longitude!)));

      return restaurants;
    } catch (e) {
      print('Error getting partner restaurants: $e');
      return [];
    }
  }

  // Get restaurant by ID
  Future<RestaurantModel?> getRestaurantById(String restaurantId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return RestaurantModel.fromJson(data);
      }
      
      return null;
    } catch (e) {
      print('Error getting restaurant by ID: $e');
      return null;
    }
  }

  // Search partner restaurants by name or cuisine
  Future<List<RestaurantModel>> searchPartnerRestaurants(String query) async {
    try {
      String queryLower = query.toLowerCase();
      
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('isPartner', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      List<RestaurantModel> restaurants = [];
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          
          RestaurantModel restaurant = RestaurantModel.fromJson(data);
          
          // Check if query matches name or cuisine types
          bool nameMatch = restaurant.name.toLowerCase().contains(queryLower);
          bool cuisineMatch = restaurant.cuisineTypes
              .any((cuisine) => cuisine.toLowerCase().contains(queryLower));
          
          if (nameMatch || cuisineMatch) {
            restaurants.add(restaurant);
          }
        } catch (e) {
          print('Error parsing restaurant ${doc.id}: $e');
        }
      }

      return restaurants;
    } catch (e) {
      print('Error searching restaurants: $e');
      return [];
    }
  }

  // Get all partner restaurants (for staff screen)
  Future<List<RestaurantModel>> getAllPartnerRestaurants() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('isPartner', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      List<RestaurantModel> restaurants = [];
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          restaurants.add(RestaurantModel.fromJson(data));
        } catch (e) {
          print('Error parsing restaurant ${doc.id}: $e');
        }
      }

      return restaurants;
    } catch (e) {
      print('Error getting all partner restaurants: $e');
      return [];
    }
  }

  // Get partner restaurants (alias for compatibility)
  Future<List<RestaurantModel>> getPartnerRestaurants() async {
    return getAllPartnerRestaurants();
  }

  // Get all partner restaurants
  Future<List<RestaurantModel>> getAllPartnerRestaurants() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('restaurants')
          .where('isPartner', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      List<RestaurantModel> restaurants = [];
      
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          restaurants.add(RestaurantModel.fromJson(data));
        } catch (e) {
          print('Error parsing restaurant ${doc.id}: $e');
        }
      }

      return restaurants;
    } catch (e) {
      print('Error getting all partner restaurants: $e');
      return [];
    }
  }

  // Add sample partner restaurants for testing
  Future<void> addSamplePartnerRestaurants() async {
    try {
      List<Map<String, dynamic>> sampleRestaurants = [
        {
          'name': 'The Garden Bistro',
          'address': '123 Main St, Downtown',
          'latitude': 37.7749,
          'longitude': -122.4194,
          'phoneNumber': '+1-555-0123',
          'website': 'https://gardenbistro.com',
          'cuisineTypes': ['Mediterranean', 'Vegetarian'],
          'rating': 4.5,
          'reviewCount': 127,
          'photoUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400',
          'isPartner': true,
          'isActive': true,
          'discountPercentage': 15.0,
          'priceRange': '\$\$',
          'ownerName': 'Maria Rodriguez',
          'contactPersonName': 'John Smith',
          'contactPersonPhone': '+1-555-0124',
          'contactPersonEmail': 'john@gardenbistro.com',
          'partnershipStartDate': DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          'maxGroupsPerDay': 10,
          'specialInstructions': ['Please mention GTKY when making reservation'],
        },
        {
          'name': 'Sakura Sushi',
          'address': '456 Oak Ave, Midtown',
          'latitude': 37.7849,
          'longitude': -122.4094,
          'phoneNumber': '+1-555-0125',
          'website': 'https://sakurasushi.com',
          'cuisineTypes': ['Japanese', 'Sushi'],
          'rating': 4.7,
          'reviewCount': 203,
          'photoUrl': 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400',
          'isPartner': true,
          'isActive': true,
          'discountPercentage': 15.0,
          'priceRange': '\$\$\$',
          'ownerName': 'Takeshi Yamamoto',
          'contactPersonName': 'Sarah Kim',
          'contactPersonPhone': '+1-555-0126',
          'contactPersonEmail': 'sarah@sakurasushi.com',
          'partnershipStartDate': DateTime.now().subtract(Duration(days: 45)).toIso8601String(),
          'maxGroupsPerDay': 8,
          'specialInstructions': ['GTKY groups get priority seating'],
        },
        {
          'name': 'Bella Italia',
          'address': '789 Pine St, Little Italy',
          'latitude': 37.7649,
          'longitude': -122.4294,
          'phoneNumber': '+1-555-0127',
          'website': 'https://bellaitalia.com',
          'cuisineTypes': ['Italian', 'Pizza'],
          'rating': 4.3,
          'reviewCount': 89,
          'photoUrl': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400',
          'isPartner': true,
          'isActive': true,
          'discountPercentage': 15.0,
          'priceRange': '\$\$',
          'ownerName': 'Giuseppe Rossi',
          'contactPersonName': 'Anna Rossi',
          'contactPersonPhone': '+1-555-0128',
          'contactPersonEmail': 'anna@bellaitalia.com',
          'partnershipStartDate': DateTime.now().subtract(Duration(days: 60)).toIso8601String(),
          'maxGroupsPerDay': 12,
          'specialInstructions': ['Free appetizer for GTKY groups'],
        },
      ];

      for (var restaurant in sampleRestaurants) {
        await _firestore.collection('restaurants').add(restaurant);
      }
      
      print('Sample partner restaurants added successfully');
    } catch (e) {
      print('Error adding sample restaurants: $e');
    }
  }
}