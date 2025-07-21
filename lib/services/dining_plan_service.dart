import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dining_plan_model.dart';
import '../models/restaurant_model.dart';
import '../models/user_model.dart';
import 'code_generation_service.dart';

class DiningPlanService {
  static final DiningPlanService _instance = DiningPlanService._internal();
  factory DiningPlanService() => _instance;
  DiningPlanService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CodeGenerationService _codeService = CodeGenerationService();

  // Create a new dining plan
  Future<String?> createDiningPlan({
    required String restaurantId,
    required DateTime plannedTime,
    String? description,
    int maxMembers = 4,
  }) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate planned time (must be between 30 minutes and 2 hours from now)
      DateTime now = DateTime.now();
      DateTime minTime = now.add(const Duration(minutes: 30));
      DateTime maxTime = now.add(const Duration(hours: 2));

      if (plannedTime.isBefore(minTime) || plannedTime.isAfter(maxTime)) {
        throw Exception('Planned time must be between 30 minutes and 2 hours from now');
      }

      // Create the dining plan
      DiningPlanModel plan = DiningPlanModel(
        id: '', // Will be set by Firestore
        creatorId: currentUser.uid,
        restaurantId: restaurantId,
        plannedTime: plannedTime,
        createdAt: DateTime.now(),
        status: PlanStatus.open,
        memberIds: [currentUser.uid], // Creator is automatically a member
        maxMembers: maxMembers,
        description: description,
      );

      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('dining_plans')
          .add(plan.toJson());

      return docRef.id;
    } catch (e) {
      print('Error creating dining plan: $e');
      return null;
    }
  }

  // Get user's dining plans
  Future<List<DiningPlanModel>> getUserDiningPlans(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('dining_plans')
          .where('memberIds', arrayContains: userId)
          .orderBy('plannedTime', descending: false)
          .get();

      List<DiningPlanModel> plans = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          plans.add(DiningPlanModel.fromJson(data));
        } catch (e) {
          print('Error parsing dining plan ${doc.id}: $e');
        }
      }

      return plans;
    } catch (e) {
      print('Error getting user dining plans: $e');
      return [];
    }
  }

  // Get open dining plans for a restaurant
  Future<List<DiningPlanModel>> getOpenPlansForRestaurant(String restaurantId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('dining_plans')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', isEqualTo: 'open')
          .orderBy('plannedTime', descending: false)
          .get();

      List<DiningPlanModel> plans = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          plans.add(DiningPlanModel.fromJson(data));
        } catch (e) {
          print('Error parsing dining plan ${doc.id}: $e');
        }
      }

      return plans;
    } catch (e) {
      print('Error getting open plans for restaurant: $e');
      return [];
    }
  }

  // Join a dining plan
  Future<bool> joinDiningPlan(String planId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current user's company
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      UserModel currentUserModel = UserModel.fromJson(
          userDoc.data() as Map<String, dynamic>);

      // Get the dining plan
      DocumentSnapshot planDoc = await _firestore
          .collection('dining_plans')
          .doc(planId)
          .get();

      if (!planDoc.exists) {
        throw Exception('Dining plan not found');
      }

      Map<String, dynamic> planData = planDoc.data() as Map<String, dynamic>;
      planData['id'] = planDoc.id;
      DiningPlanModel plan = DiningPlanModel.fromJson(planData);

      // Check if plan is still open and has space
      if (plan.status != PlanStatus.open) {
        throw Exception('This plan is no longer open');
      }

      if (plan.isFull) {
        throw Exception('This plan is already full');
      }

      if (plan.hasUser(currentUser.uid)) {
        throw Exception('You are already in this plan');
      }

      // Check company verification - users must be from different companies
      for (String memberId in plan.memberIds) {
        DocumentSnapshot memberDoc = await _firestore
            .collection('users')
            .doc(memberId)
            .get();

        if (memberDoc.exists) {
          UserModel member = UserModel.fromJson(
              memberDoc.data() as Map<String, dynamic>);
          
          if (member.company == currentUserModel.company) {
            throw Exception('You cannot join a plan with someone from your company');
          }
        }
      }

      // Add user to the plan
      List<String> updatedMemberIds = List.from(plan.memberIds);
      updatedMemberIds.add(currentUser.uid);

      // Check if plan is now full and generate codes if needed
      Map<String, dynamic> updateData = {
        'memberIds': updatedMemberIds,
      };

      // If plan is now full, generate codes and mark as matched
      if (updatedMemberIds.length >= plan.maxMembers) {
        final codes = _codeService.generateCodesForPlan(updatedMemberIds);
        updateData['memberCodes'] = codes;
        updateData['status'] = 'matched';
        updateData['confirmedAt'] = DateTime.now().toIso8601String();
      }

      await _firestore.collection('dining_plans').doc(planId).update(updateData);

      return true;
    } catch (e) {
      print('Error joining dining plan: $e');
      return false;
    }
  }

  // Leave a dining plan
  Future<bool> leaveDiningPlan(String planId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the dining plan
      DocumentSnapshot planDoc = await _firestore
          .collection('dining_plans')
          .doc(planId)
          .get();

      if (!planDoc.exists) {
        throw Exception('Dining plan not found');
      }

      Map<String, dynamic> planData = planDoc.data() as Map<String, dynamic>;
      planData['id'] = planDoc.id;
      DiningPlanModel plan = DiningPlanModel.fromJson(planData);

      if (!plan.hasUser(currentUser.uid)) {
        throw Exception('You are not in this plan');
      }

      // Remove user from the plan
      List<String> updatedMemberIds = List.from(plan.memberIds);
      updatedMemberIds.remove(currentUser.uid);

      if (updatedMemberIds.isEmpty) {
        // If no members left, delete the plan
        await _firestore.collection('dining_plans').doc(planId).delete();
      } else {
        // Update the plan
        await _firestore.collection('dining_plans').doc(planId).update({
          'memberIds': updatedMemberIds,
        });
      }

      return true;
    } catch (e) {
      print('Error leaving dining plan: $e');
      return false;
    }
  }

  // Get dining plan by ID
  Future<DiningPlanModel?> getDiningPlanById(String planId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('dining_plans')
          .doc(planId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return DiningPlanModel.fromJson(data);
      }

      return null;
    } catch (e) {
      print('Error getting dining plan by ID: $e');
      return null;
    }
  }

  // Get open plans for discovery (excluding user's own plans)
  Future<List<DiningPlanModel>> getOpenPlansForDiscovery(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('dining_plans')
          .where('status', isEqualTo: 'open')
          .where('creatorId', isNotEqualTo: userId)
          .orderBy('creatorId')
          .orderBy('plannedTime', descending: false)
          .get();

      List<DiningPlanModel> plans = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          DiningPlanModel plan = DiningPlanModel.fromJson(data);
          
          // Exclude plans where user is already a member
          if (!plan.hasUser(userId) && !plan.isFull) {
            plans.add(plan);
          }
        } catch (e) {
          print('Error parsing dining plan ${doc.id}: $e');
        }
      }

      return plans;
    } catch (e) {
      print('Error getting open plans for discovery: $e');
      return [];
    }
  }

  // Stream of user's dining plans
  Stream<List<DiningPlanModel>> getUserDiningPlansStream(String userId) {
    return _firestore
        .collection('dining_plans')
        .where('memberIds', arrayContains: userId)
        .orderBy('plannedTime', descending: false)
        .snapshots()
        .map((snapshot) {
      List<DiningPlanModel> plans = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          plans.add(DiningPlanModel.fromJson(data));
        } catch (e) {
          print('Error parsing dining plan ${doc.id}: $e');
        }
      }
      return plans;
    });
  }

  // Confirm user arrival at restaurant
  Future<bool> confirmArrival(String planId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get the dining plan
      DocumentSnapshot planDoc = await _firestore
          .collection('dining_plans')
          .doc(planId)
          .get();

      if (!planDoc.exists) {
        throw Exception('Dining plan not found');
      }

      Map<String, dynamic> planData = planDoc.data() as Map<String, dynamic>;
      planData['id'] = planDoc.id;
      DiningPlanModel plan = DiningPlanModel.fromJson(planData);

      if (!plan.hasUser(currentUser.uid)) {
        throw Exception('You are not part of this plan');
      }

      // Add user to arrived members list
      List<String> arrivedMembers = List.from(plan.arrivedMemberIds ?? []);
      if (!arrivedMembers.contains(currentUser.uid)) {
        arrivedMembers.add(currentUser.uid);
      }

      // Update plan status if all members have arrived
      Map<String, dynamic> updateData = {
        'arrivedMemberIds': arrivedMembers,
      };

      if (arrivedMembers.length == plan.memberIds.length) {
        updateData['status'] = 'completed';
        updateData['completedAt'] = DateTime.now().toIso8601String();
      }

      await _firestore.collection('dining_plans').doc(planId).update(updateData);

      return true;
    } catch (e) {
      print('Error confirming arrival: $e');
      return false;
    }
  }

  // Get active plans for a specific restaurant
  Future<List<DiningPlanModel>> getActivePlansForRestaurant(String restaurantId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('dining_plans')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('status', whereIn: ['matched', 'confirmed'])
          .orderBy('plannedTime', descending: false)
          .get();

      List<DiningPlanModel> plans = [];
      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          DiningPlanModel plan = DiningPlanModel.fromJson(data);
          
          // Only include plans with codes (matched plans)
          if (plan.memberCodes != null && plan.memberCodes!.isNotEmpty) {
            plans.add(plan);
          }
        } catch (e) {
          print('Error parsing dining plan ${doc.id}: $e');
        }
      }

      return plans;
    } catch (e) {
      print('Error getting active plans for restaurant: $e');
      return [];
    }
  }

  // Mark a specific user as arrived (for restaurant staff)
  Future<bool> markUserArrived(String planId, String userId) async {
    try {
      // Get the dining plan
      DocumentSnapshot planDoc = await _firestore
          .collection('dining_plans')
          .doc(planId)
          .get();

      if (!planDoc.exists) {
        throw Exception('Dining plan not found');
      }

      Map<String, dynamic> planData = planDoc.data() as Map<String, dynamic>;
      planData['id'] = planDoc.id;
      DiningPlanModel plan = DiningPlanModel.fromJson(planData);

      if (!plan.hasUser(userId)) {
        throw Exception('User is not part of this plan');
      }

      // Add user to arrived members list
      List<String> arrivedMembers = List.from(plan.arrivedMemberIds ?? []);
      if (!arrivedMembers.contains(userId)) {
        arrivedMembers.add(userId);
      }

      // Update plan status if all members have arrived
      Map<String, dynamic> updateData = {
        'arrivedMemberIds': arrivedMembers,
      };

      if (arrivedMembers.length == plan.memberIds.length) {
        updateData['status'] = 'completed';
        updateData['completedAt'] = DateTime.now().toIso8601String();
      }

      await _firestore.collection('dining_plans').doc(planId).update(updateData);

      return true;
    } catch (e) {
      print('Error marking user as arrived: $e');
      return false;
    }
  }

  // Complete a dining plan (mark as completed)
  Future<bool> completePlan(String planId) async {
    try {
      await _firestore.collection('dining_plans').doc(planId).update({
        'status': PlanStatus.completed.toString().split('.').last,
        'completedAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error completing plan: $e');
      return false;
    }
  }
}