import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/restaurant_model.dart';
import '../models/dining_plan_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _restaurants => _db.collection('restaurants');
  CollectionReference get _diningPlans => _db.collection('dining_plans');
  CollectionReference get _matches => _db.collection('matches');

  // User operations
  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toJson());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateUser(UserModel user) async {
    await _users.doc(user.id).update(user.toJson());
  }

  Future<void> updateUserLastActive(String userId) async {
    await _users.doc(userId).update({
      'lastActive': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteUser(String userId) async {
    await _users.doc(userId).delete();
  }

  // Restaurant operations
  Future<void> createRestaurant(RestaurantModel restaurant) async {
    await _restaurants.doc(restaurant.id).set(restaurant.toJson());
  }

  Future<RestaurantModel?> getRestaurant(String restaurantId) async {
    final doc = await _restaurants.doc(restaurantId).get();
    if (doc.exists) {
      return RestaurantModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<RestaurantModel>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    // Note: For production, consider using GeoFlutterFire for better geo queries
    final query = await _restaurants
        .where('isPartner', isEqualTo: true)
        .limit(limit)
        .get();

    final restaurants = query.docs
        .map((doc) => RestaurantModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((restaurant) => 
            restaurant.distanceFrom(latitude, longitude) <= radiusKm)
        .toList();

    // Sort by distance
    restaurants.sort((a, b) => 
        a.distanceFrom(latitude, longitude)
            .compareTo(b.distanceFrom(latitude, longitude)));

    return restaurants;
  }

  Future<List<RestaurantModel>> searchRestaurants(String query) async {
    final results = await _restaurants
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .limit(20)
        .get();

    return results.docs
        .map((doc) => RestaurantModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Dining plan operations
  Future<String> createDiningPlan(DiningPlanModel plan) async {
    final docRef = await _diningPlans.add(plan.toJson());
    return docRef.id;
  }

  Future<DiningPlanModel?> getDiningPlan(String planId) async {
    final doc = await _diningPlans.doc(planId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return DiningPlanModel.fromJson(data);
    }
    return null;
  }

  Future<void> updateDiningPlan(DiningPlanModel plan) async {
    await _diningPlans.doc(plan.id).update(plan.toJson());
  }

  Future<List<DiningPlanModel>> getOpenPlansForRestaurant({
    required String restaurantId,
    required String currentUserId,
    required String userCompany,
  }) async {
    final query = await _diningPlans
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: 'open')
        .where('plannedTime', isGreaterThan: DateTime.now().toIso8601String())
        .get();

    final plans = <DiningPlanModel>[];
    
    for (final doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      final plan = DiningPlanModel.fromJson(data);
      
      // Check if user can join (different company requirement)
      if (await _canUserJoinPlan(plan, currentUserId, userCompany)) {
        plans.add(plan);
      }
    }

    return plans;
  }

  Future<List<DiningPlanModel>> getUserPlans(String userId) async {
    final query = await _diningPlans
        .where('memberIds', arrayContains: userId)
        .orderBy('plannedTime', descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return DiningPlanModel.fromJson(data);
    }).toList();
  }

  // Check if user can join a plan (different company requirement)
  Future<bool> _canUserJoinPlan(
    DiningPlanModel plan, 
    String userId, 
    String userCompany
  ) async {
    if (plan.hasUser(userId) || !plan.canJoin) {
      return false;
    }

    // Check if all current members are from different companies
    for (final memberId in plan.memberIds) {
      final member = await getUser(memberId);
      if (member != null && member.company == userCompany) {
        return false; // Same company found
      }
    }

    return true;
  }

  // Join a dining plan
  Future<bool> joinDiningPlan(String planId, String userId) async {
    try {
      final plan = await getDiningPlan(planId);
      if (plan == null || !plan.canJoin) return false;

      final updatedMemberIds = [...plan.memberIds, userId];
      final updatedPlan = plan.copyWith(
        memberIds: updatedMemberIds,
        status: updatedMemberIds.length >= plan.maxMembers 
            ? PlanStatus.matched 
            : PlanStatus.open,
      );

      await updateDiningPlan(updatedPlan);
      return true;
    } catch (e) {
      print('Error joining dining plan: $e');
      return false;
    }
  }

  // Generate unique codes for matched group
  Future<void> generateCodesForPlan(String planId) async {
    final plan = await getDiningPlan(planId);
    if (plan == null || plan.status != PlanStatus.matched) return;

    final codes = <String, String>{};
    final usedCodes = <String>{};

    for (final memberId in plan.memberIds) {
      String code;
      do {
        code = _generateTwoDigitCode();
      } while (usedCodes.contains(code));
      
      usedCodes.add(code);
      codes[memberId] = code;
    }

    final updatedPlan = plan.copyWith(
      memberCodes: codes,
      status: PlanStatus.confirmed,
      confirmedAt: DateTime.now(),
    );

    await updateDiningPlan(updatedPlan);
  }

  String _generateTwoDigitCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    return random.toString().padLeft(2, '0');
  }

  // Mark user as arrived
  Future<void> markUserArrived(String planId, String userId) async {
    final plan = await getDiningPlan(planId);
    if (plan == null) return;

    final arrivedIds = plan.arrivedMemberIds ?? [];
    if (!arrivedIds.contains(userId)) {
      arrivedIds.add(userId);
    }

    final updatedPlan = plan.copyWith(
      arrivedMemberIds: arrivedIds,
      status: arrivedIds.length == plan.memberIds.length 
          ? PlanStatus.completed 
          : plan.status,
    );

    await updateDiningPlan(updatedPlan);
  }
}