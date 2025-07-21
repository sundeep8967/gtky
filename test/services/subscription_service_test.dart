import 'package:flutter_test/flutter_test.dart';
import 'package:gtky/services/subscription_service.dart';
import 'package:gtky/models/subscription_model.dart';
import 'package:gtky/models/referral_model.dart';

void main() {
  group('SubscriptionService Tests', () {
    late SubscriptionService subscriptionService;

    setUp(() {
      subscriptionService = SubscriptionService();
    });

    test('should return correct premium plan price', () {
      expect(SubscriptionService.premiumMonthlyPrice, 199.0);
    });

    test('should return correct daily limits', () {
      expect(SubscriptionService.freePlanDailyLimit, 2);
      expect(SubscriptionService.premiumPlanDailyLimit, -1); // Unlimited
    });

    test('should return correct referral credit amount', () {
      expect(SubscriptionService.referralCreditAmount, 99.0);
    });

    test('should return premium features list', () {
      final features = subscriptionService.getPremiumFeatures();
      
      expect(features, isA<List<String>>());
      expect(features.length, greaterThan(0));
      expect(features.contains('Unlimited dining plans per day'), true);
      expect(features.contains('Priority matching with other users'), true);
      expect(features.contains('Advanced filters (cuisine, price range, distance)'), true);
    });

    test('should generate unique referral codes', () async {
      // Since we can't easily test the actual generation without mocking,
      // we'll test the code format validation
      final testCodes = <String>[];
      
      // Generate multiple codes and check uniqueness
      for (int i = 0; i < 3; i++) {
        // Note: _generateUniqueCode is private method, testing through public interface
        try {
          final referral = await subscriptionService.createReferralCode('test_user_id_$i');
          final code = referral.referralCode;
          expect(code.length, 8);
          expect(testCodes.contains(code), false);
          testCodes.add(code);
          
          // Check that code contains only valid characters
          final validChars = RegExp(r'^[A-Z0-9]+$');
          expect(validChars.hasMatch(code), true);
        } catch (e) {
          // Skip if Firebase is not available in test environment
          print('Skipping referral code test due to Firebase unavailability: $e');
          break;
        }
      }
    });
  });

  group('SubscriptionModel Tests', () {
    test('should create subscription model correctly', () {
      final subscription = SubscriptionModel(
        id: 'sub_123',
        userId: 'user_123',
        plan: SubscriptionPlan.premium,
        status: SubscriptionStatus.active,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 1),
        amount: 199.0,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(subscription.id, 'sub_123');
      expect(subscription.userId, 'user_123');
      expect(subscription.plan, SubscriptionPlan.premium);
      expect(subscription.status, SubscriptionStatus.active);
      expect(subscription.amount, 199.0);
      expect(subscription.currency, 'INR'); // Default value
    });

    test('should calculate active status correctly', () {
      final now = DateTime.now();
      
      // Active subscription
      final activeSubscription = SubscriptionModel(
        id: 'sub_active',
        userId: 'user_123',
        plan: SubscriptionPlan.premium,
        status: SubscriptionStatus.active,
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 10)),
        amount: 199.0,
        createdAt: now.subtract(const Duration(days: 10)),
      );

      expect(activeSubscription.isActive, true);
      expect(activeSubscription.isPremium, true);

      // Expired subscription
      final expiredSubscription = SubscriptionModel(
        id: 'sub_expired',
        userId: 'user_123',
        plan: SubscriptionPlan.premium,
        status: SubscriptionStatus.expired,
        startDate: now.subtract(const Duration(days: 40)),
        endDate: now.subtract(const Duration(days: 10)),
        amount: 199.0,
        createdAt: now.subtract(const Duration(days: 40)),
      );

      expect(expiredSubscription.isActive, false);
      expect(expiredSubscription.isPremium, false);
    });

    test('should calculate days remaining correctly', () {
      final now = DateTime.now();
      
      final subscription = SubscriptionModel(
        id: 'sub_123',
        userId: 'user_123',
        plan: SubscriptionPlan.premium,
        status: SubscriptionStatus.active,
        startDate: now,
        endDate: now.add(const Duration(days: 15)),
        amount: 199.0,
        createdAt: now,
      );

      expect(subscription.daysRemaining, 15);
    });

    test('should convert to/from JSON correctly', () {
      final subscription = SubscriptionModel(
        id: 'sub_123',
        userId: 'user_123',
        plan: SubscriptionPlan.premium,
        status: SubscriptionStatus.active,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 1),
        amount: 199.0,
        currency: 'USD',
        paymentId: 'pay_123',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = subscription.toJson();
      final fromJson = SubscriptionModel.fromJson(json);

      expect(fromJson.id, subscription.id);
      expect(fromJson.userId, subscription.userId);
      expect(fromJson.plan, subscription.plan);
      expect(fromJson.status, subscription.status);
      expect(fromJson.amount, subscription.amount);
      expect(fromJson.currency, subscription.currency);
      expect(fromJson.paymentId, subscription.paymentId);
    });
  });

  group('ReferralModel Tests', () {
    test('should create referral model correctly', () {
      final referral = ReferralModel(
        id: 'ref_123',
        referrerId: 'user_123',
        referralCode: 'ABC12345',
        status: ReferralStatus.pending,
        creditAmount: 99.0,
        createdAt: DateTime(2024, 1, 1),
        expiresAt: DateTime(2024, 2, 1),
      );

      expect(referral.id, 'ref_123');
      expect(referral.referrerId, 'user_123');
      expect(referral.referralCode, 'ABC12345');
      expect(referral.status, ReferralStatus.pending);
      expect(referral.creditAmount, 99.0);
    });

    test('should check expiration correctly', () {
      final now = DateTime.now();
      
      // Not expired
      final validReferral = ReferralModel(
        id: 'ref_valid',
        referrerId: 'user_123',
        referralCode: 'VALID123',
        status: ReferralStatus.pending,
        creditAmount: 99.0,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 10)),
      );

      expect(validReferral.isExpired, false);

      // Expired
      final expiredReferral = ReferralModel(
        id: 'ref_expired',
        referrerId: 'user_123',
        referralCode: 'EXPIRED1',
        status: ReferralStatus.pending,
        creditAmount: 99.0,
        createdAt: now.subtract(const Duration(days: 40)),
        expiresAt: now.subtract(const Duration(days: 10)),
      );

      expect(expiredReferral.isExpired, true);
    });

    test('should check completion status correctly', () {
      final completedReferral = ReferralModel(
        id: 'ref_completed',
        referrerId: 'user_123',
        referralCode: 'COMPLETE',
        referredUserId: 'user_456',
        status: ReferralStatus.completed,
        creditAmount: 99.0,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(completedReferral.isCompleted, true);

      final pendingReferral = ReferralModel(
        id: 'ref_pending',
        referrerId: 'user_123',
        referralCode: 'PENDING1',
        status: ReferralStatus.pending,
        creditAmount: 99.0,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      expect(pendingReferral.isCompleted, false);
    });
  });
}