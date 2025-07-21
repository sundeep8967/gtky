import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';
import '../models/referral_model.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _subscriptions => _db.collection('subscriptions');
  CollectionReference get _referrals => _db.collection('referrals');
  CollectionReference get _users => _db.collection('users');

  // Premium plan details
  static const double premiumMonthlyPrice = 199.0;
  static const String premiumPlanId = 'premium_monthly';
  
  // Premium features
  static const int freePlanDailyLimit = 2;
  static const int premiumPlanDailyLimit = -1; // Unlimited
  
  // Referral rewards
  static const double referralCreditAmount = 99.0; // Half month free
  
  // Get user's current subscription
  Future<SubscriptionModel?> getUserSubscription(String userId) async {
    try {
      final query = await _subscriptions
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return SubscriptionModel.fromJson(query.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user subscription: $e');
      return null;
    }
  }

  // Check if user has premium subscription
  Future<bool> isUserPremium(String userId) async {
    try {
      final subscription = await getUserSubscription(userId);
      return subscription?.isPremium ?? false;
    } catch (e) {
      print('Error checking premium status: $e');
      return false;
    }
  }

  // Create premium subscription
  Future<SubscriptionModel?> createPremiumSubscription({
    required String userId,
    required String paymentId,
  }) async {
    try {
      final subscriptionId = _subscriptions.doc().id;
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30)); // 1 month

      final subscription = SubscriptionModel(
        id: subscriptionId,
        userId: userId,
        plan: SubscriptionPlan.premium,
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: endDate,
        amount: premiumMonthlyPrice,
        paymentId: paymentId,
        createdAt: now,
      );

      await _subscriptions.doc(subscriptionId).set(subscription.toJson());
      
      // Update user's premium status
      await _updateUserPremiumStatus(userId, true);
      
      print('Premium subscription created successfully');
      return subscription;
    } catch (e) {
      print('Error creating premium subscription: $e');
      throw Exception('Failed to create premium subscription');
    }
  }

  // Cancel subscription
  Future<void> cancelSubscription(String userId, String reason) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (subscription == null) {
        throw Exception('No active subscription found');
      }

      await _subscriptions.doc(subscription.id).update({
        'status': SubscriptionStatus.cancelled.name,
        'cancelledAt': DateTime.now().toIso8601String(),
        'cancellationReason': reason,
      });

      // Update user's premium status
      await _updateUserPremiumStatus(userId, false);
      
      print('Subscription cancelled successfully');
    } catch (e) {
      print('Error cancelling subscription: $e');
      throw Exception('Failed to cancel subscription');
    }
  }

  // Get subscription history
  Future<List<SubscriptionModel>> getSubscriptionHistory(String userId) async {
    try {
      final query = await _subscriptions
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => SubscriptionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  // Generate referral code
  Future<ReferralModel> generateReferralCode(String userId) async {
    try {
      final referralId = _referrals.doc().id;
      final referralCode = _generateUniqueCode();
      final now = DateTime.now();
      
      final referral = ReferralModel(
        id: referralId,
        referrerId: userId,
        referralCode: referralCode,
        status: ReferralStatus.pending,
        creditAmount: referralCreditAmount,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 30)),
      );

      await _referrals.doc(referralId).set(referral.toJson());
      return referral;
    } catch (e) {
      print('Error generating referral code: $e');
      throw Exception('Failed to generate referral code');
    }
  }

  // Apply referral code
  Future<bool> applyReferralCode(String userId, String referralCode) async {
    try {
      final query = await _referrals
          .where('referralCode', isEqualTo: referralCode)
          .where('status', isEqualTo: ReferralStatus.pending.name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Invalid or expired referral code');
      }

      final referralDoc = query.docs.first;
      final referral = ReferralModel.fromJson(referralDoc.data() as Map<String, dynamic>);

      if (referral.referrerId == userId) {
        throw Exception('Cannot use your own referral code');
      }

      if (referral.isExpired) {
        throw Exception('Referral code has expired');
      }

      // Update referral status
      await _referrals.doc(referral.id).update({
        'referredUserId': userId,
        'status': ReferralStatus.completed.name,
        'completedAt': DateTime.now().toIso8601String(),
      });

      // Add credit to referrer (implement credit system later)
      await _addReferralCredit(referral.referrerId, referral.creditAmount);
      
      print('Referral code applied successfully');
      return true;
    } catch (e) {
      print('Error applying referral code: $e');
      return false;
    }
  }

  // Get user's referrals
  Future<List<ReferralModel>> getUserReferrals(String userId) async {
    try {
      final query = await _referrals
          .where('referrerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ReferralModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user referrals: $e');
      return [];
    }
  }

  // Check daily plan limit
  Future<bool> canCreatePlan(String userId) async {
    try {
      final isPremium = await isUserPremium(userId);
      if (isPremium) return true; // Unlimited for premium users

      // Check today's plan count for free users
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _db.collection('dining_plans')
          .where('creatorId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('createdAt', isLessThan: endOfDay.toIso8601String())
          .get();

      return query.docs.length < freePlanDailyLimit;
    } catch (e) {
      print('Error checking plan limit: $e');
      return false;
    }
  }

  // Get premium features list
  List<String> getPremiumFeatures() {
    return [
      'Unlimited dining plans per day',
      'Priority matching with other users',
      'Advanced filters (cuisine, price range, distance)',
      'Premium user badge',
      'Early access to new restaurants',
      'Priority customer support',
      'Exclusive premium-only events',
      'Enhanced profile visibility',
    ];
  }

  // Private helper methods
  Future<void> _updateUserPremiumStatus(String userId, bool isPremium) async {
    try {
      await _users.doc(userId).update({
        'isPremium': isPremium,
        'premiumUpdatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating user premium status: $e');
    }
  }

  Future<void> _addReferralCredit(String userId, double amount) async {
    try {
      // For now, just log the credit. In a real app, you'd implement a credit system
      print('Adding ₹$amount credit to user $userId');
      
      // You could store credits in a separate collection or user document
      await _users.doc(userId).update({
        'referralCredits': FieldValue.increment(amount),
      });
    } catch (e) {
      print('Error adding referral credit: $e');
    }
  }

  String _generateUniqueCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(8, (index) => chars[random % chars.length]).join();
  }
}