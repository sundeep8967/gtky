import 'dart:math';
import '../models/dining_plan_model.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class MatchingService {
  static final MatchingService _instance = MatchingService._internal();
  factory MatchingService() => _instance;
  MatchingService._internal();

  final FirestoreService _firestoreService = FirestoreService();

  // Find potential matches for a dining plan
  Future<List<DiningPlanModel>> findPotentialMatches({
    required String userId,
    required String restaurantId,
    required DateTime plannedTime,
    required String userCompany,
  }) async {
    try {
      // Get open plans for the same restaurant
      final openPlans = await _firestoreService.getOpenPlansForRestaurant(
        restaurantId: restaurantId,
        currentUserId: userId,
        userCompany: userCompany,
      );

      // Filter plans by time overlap (within 30 minutes)
      final matchingPlans = openPlans.where((plan) {
        final timeDifference = plan.plannedTime.difference(plannedTime).abs();
        return timeDifference.inMinutes <= 30;
      }).toList();

      return matchingPlans;
    } catch (e) {
      print('Error finding potential matches: $e');
      return [];
    }
  }

  // Create a match when users join a plan
  Future<MatchModel?> createMatch(DiningPlanModel plan) async {
    try {
      if (plan.memberIds.length < 2) {
        return null; // Need at least 2 people for a match
      }

      // Generate unique codes for all members
      final memberCodes = <String, String>{};
      final usedCodes = <String>{};

      for (final memberId in plan.memberIds) {
        String code;
        do {
          code = _generateTwoDigitCode();
        } while (usedCodes.contains(code));
        
        usedCodes.add(code);
        memberCodes[memberId] = code;
      }

      final match = MatchModel(
        id: _generateUniqueId(),
        planId: plan.id,
        memberIds: plan.memberIds,
        restaurantId: plan.restaurantId,
        plannedTime: plan.plannedTime,
        createdAt: DateTime.now(),
        status: MatchStatus.confirmed,
        memberCodes: memberCodes,
        confirmedAt: DateTime.now(),
      );

      // Save match to database
      await _firestoreService.createMatch(match.toJson());

      // Update plan status
      final updatedPlan = plan.copyWith(
        status: PlanStatus.matched,
        memberCodes: memberCodes,
        confirmedAt: DateTime.now(),
      );
      await _firestoreService.updateDiningPlan(updatedPlan);

      return match;
    } catch (e) {
      print('Error creating match: $e');
      return null;
    }
  }

  // Check if users can be matched (different companies)
  Future<bool> canUsersBeMatched(List<String> userIds) async {
    try {
      final users = <UserModel>[];
      for (final userId in userIds) {
        final user = await _firestoreService.getUser(userId);
        if (user != null) {
          users.add(user);
        }
      }

      if (users.length != userIds.length) {
        return false; // Some users not found
      }

      // Check if all users are from different companies
      final companies = users.map((user) => user.company).toSet();
      return companies.length == users.length;
    } catch (e) {
      print('Error checking user compatibility: $e');
      return false;
    }
  }

  // Auto-match users when they create plans
  Future<void> processAutoMatching(DiningPlanModel newPlan) async {
    try {
      final creator = await _firestoreService.getUser(newPlan.creatorId);
      if (creator == null) return;

      // Find potential matches
      final potentialMatches = await findPotentialMatches(
        userId: newPlan.creatorId,
        restaurantId: newPlan.restaurantId,
        plannedTime: newPlan.plannedTime,
        userCompany: creator.company,
      );

      // Try to join the best matching plan
      for (final existingPlan in potentialMatches) {
        if (existingPlan.canJoin) {
          final canMatch = await canUsersBeMatched([
            ...existingPlan.memberIds,
            newPlan.creatorId,
          ]);

          if (canMatch) {
            // Join the existing plan
            final success = await _firestoreService.joinDiningPlan(
              existingPlan.id,
              newPlan.creatorId,
            );

            if (success) {
              // Delete the new plan since user joined existing one
              await _firestoreService.deleteDiningPlan(newPlan.id);
              
              // Check if the existing plan is now full and create match
              final updatedPlan = await _firestoreService.getDiningPlan(existingPlan.id);
              if (updatedPlan != null && updatedPlan.isFull) {
                await createMatch(updatedPlan);
              }
              return;
            }
          }
        }
      }
    } catch (e) {
      print('Error in auto-matching: $e');
    }
  }

  // Mark user as arrived at restaurant
  Future<bool> markUserArrived(String matchId, String userId, String verificationCode) async {
    try {
      final matchData = await _firestoreService.getMatch(matchId);
      if (matchData == null) return false;

      final match = MatchModel.fromJson(matchData);

      // Verify the code
      final expectedCode = match.getCodeForUser(userId);
      if (expectedCode != verificationCode) {
        return false; // Invalid code
      }

      // Mark user as arrived
      final arrivedIds = [...match.arrivedMemberIds];
      if (!arrivedIds.contains(userId)) {
        arrivedIds.add(userId);
      }

      final updatedMatch = match.copyWith(
        arrivedMemberIds: arrivedIds,
        status: arrivedIds.length == match.memberIds.length 
            ? MatchStatus.completed 
            : MatchStatus.arrived,
      );

      await _firestoreService.updateMatch(matchId, updatedMatch.toJson());
      return true;
    } catch (e) {
      print('Error marking user arrived: $e');
      return false;
    }
  }

  // Calculate discount amount
  double calculateDiscount(double billAmount, double discountPercentage) {
    return billAmount * (discountPercentage / 100);
  }

  // Complete a match with bill details
  Future<bool> completeMatch(String matchId, double totalBill) async {
    try {
      final matchData = await _firestoreService.getMatch(matchId);
      if (matchData == null) return false;

      final match = MatchModel.fromJson(matchData);
      if (!match.allMembersArrived) return false;

      // Get restaurant details for discount percentage
      final restaurant = await _firestoreService.getRestaurant(match.restaurantId);
      final discountPercentage = restaurant?.discountPercentage ?? 15.0;
      
      final discountAmount = calculateDiscount(totalBill, discountPercentage);

      final updatedMatch = match.copyWith(
        status: MatchStatus.completed,
        completedAt: DateTime.now(),
        totalBill: totalBill,
        discountAmount: discountAmount,
      );

      await _firestoreService.updateMatch(matchId, updatedMatch.toJson());
      return true;
    } catch (e) {
      print('Error completing match: $e');
      return false;
    }
  }

  String _generateTwoDigitCode() {
    final random = Random();
    final code = random.nextInt(100);
    return code.toString().padLeft(2, '0');
  }

  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}