import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating_model.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit a restaurant rating
  Future<bool> submitRestaurantRating({
    required String restaurantId,
    required int rating,
    String? comment,
    List<String> tags = const [],
    String? planId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final ratingModel = RatingModel(
        id: '', // Will be set by Firestore
        raterId: currentUser.uid,
        ratedId: restaurantId,
        type: RatingType.restaurant,
        rating: rating,
        comment: comment,
        tags: tags,
        createdAt: DateTime.now(),
        planId: planId,
      );

      await _firestore.collection('ratings').add(ratingModel.toJson());
      return true;
    } catch (e) {
      print('Error submitting restaurant rating: $e');
      return false;
    }
  }

  // Submit a user rating (anonymous)
  Future<bool> submitUserRating({
    required String ratedUserId,
    required int rating,
    String? comment,
    List<String> tags = const [],
    String? planId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final ratingModel = RatingModel(
        id: '', // Will be set by Firestore
        raterId: currentUser.uid,
        ratedId: ratedUserId,
        type: RatingType.user,
        rating: rating,
        comment: comment,
        tags: tags,
        createdAt: DateTime.now(),
        planId: planId,
        isAnonymous: true,
      );

      await _firestore.collection('ratings').add(ratingModel.toJson());
      return true;
    } catch (e) {
      print('Error submitting user rating: $e');
      return false;
    }
  }

  // Get restaurant ratings
  Future<List<RatingModel>> getRestaurantRatings(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('ratedId', isEqualTo: restaurantId)
          .where('type', isEqualTo: 'restaurant')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RatingModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting restaurant ratings: $e');
      return [];
    }
  }

  // Get average restaurant rating
  Future<double> getRestaurantAverageRating(String restaurantId) async {
    try {
      final ratings = await getRestaurantRatings(restaurantId);
      if (ratings.isEmpty) return 0.0;

      final sum = ratings.fold<int>(0, (sum, rating) => sum + rating.rating);
      return sum / ratings.length;
    } catch (e) {
      print('Error calculating average rating: $e');
      return 0.0;
    }
  }

  // Check if user has already rated a restaurant for a specific plan
  Future<bool> hasUserRatedRestaurant(String restaurantId, String? planId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      Query query = _firestore
          .collection('ratings')
          .where('raterId', isEqualTo: currentUser.uid)
          .where('ratedId', isEqualTo: restaurantId)
          .where('type', isEqualTo: 'restaurant');

      if (planId != null) {
        query = query.where('planId', isEqualTo: planId);
      }

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user rated restaurant: $e');
      return false;
    }
  }

  // Check if user has already rated another user for a specific plan
  Future<bool> hasUserRatedUser(String ratedUserId, String? planId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      Query query = _firestore
          .collection('ratings')
          .where('raterId', isEqualTo: currentUser.uid)
          .where('ratedId', isEqualTo: ratedUserId)
          .where('type', isEqualTo: 'user');

      if (planId != null) {
        query = query.where('planId', isEqualTo: planId);
      }

      final snapshot = await query.get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user rated user: $e');
      return false;
    }
  }

  // Get user's average rating (received from others)
  Future<double> getUserAverageRating(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('ratedId', isEqualTo: userId)
          .where('type', isEqualTo: 'user')
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final ratings = snapshot.docs.map((doc) => RatingModel.fromJson(doc.data())).toList();
      final sum = ratings.fold<int>(0, (sum, rating) => sum + rating.rating);
      return sum / ratings.length;
    } catch (e) {
      print('Error getting user average rating: $e');
      return 0.0;
    }
  }
}