import 'package:flutter_test/flutter_test.dart';
import 'package:gtky/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    late UserModel testUser;

    setUp(() {
      testUser = UserModel(
        id: 'test_user_123',
        email: 'test@example.com',
        name: 'Test User',
        age: 25,
        profilePhotoUrl: 'https://example.com/photo.jpg',
        company: 'Test Company',
        foodPreferences: ['Italian', 'Chinese'],
        latitude: 37.7749,
        longitude: -122.4194,
        createdAt: DateTime(2024, 1, 1),
        lastActive: DateTime(2024, 1, 2),
        isVerified: true,
        trustScore: 8.5,
        isPremium: true,
        referralCredits: 100.0,
      );
    });

    test('should create UserModel with all properties', () {
      expect(testUser.id, 'test_user_123');
      expect(testUser.email, 'test@example.com');
      expect(testUser.name, 'Test User');
      expect(testUser.age, 25);
      expect(testUser.profilePhotoUrl, 'https://example.com/photo.jpg');
      expect(testUser.company, 'Test Company');
      expect(testUser.foodPreferences, ['Italian', 'Chinese']);
      expect(testUser.latitude, 37.7749);
      expect(testUser.longitude, -122.4194);
      expect(testUser.isVerified, true);
      expect(testUser.trustScore, 8.5);
      expect(testUser.isPremium, true);
      expect(testUser.referralCredits, 100.0);
    });

    test('should convert to JSON correctly', () {
      final json = testUser.toJson();
      
      expect(json['id'], 'test_user_123');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
      expect(json['age'], 25);
      expect(json['profilePhotoUrl'], 'https://example.com/photo.jpg');
      expect(json['company'], 'Test Company');
      expect(json['foodPreferences'], ['Italian', 'Chinese']);
      expect(json['latitude'], 37.7749);
      expect(json['longitude'], -122.4194);
      expect(json['isVerified'], true);
      expect(json['trustScore'], 8.5);
      expect(json['isPremium'], true);
      expect(json['referralCredits'], 100.0);
    });

    test('should create UserModel from JSON correctly', () {
      final json = {
        'id': 'test_user_456',
        'email': 'test2@example.com',
        'name': 'Test User 2',
        'age': 30,
        'profilePhotoUrl': 'https://example.com/photo2.jpg',
        'company': 'Test Company 2',
        'foodPreferences': ['Mexican', 'Thai'],
        'latitude': 40.7128,
        'longitude': -74.0060,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'lastActive': '2024-01-02T00:00:00.000Z',
        'isVerified': false,
        'trustScore': 7.0,
        'isPremium': false,
        'referralCredits': 50.0,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'test_user_456');
      expect(user.email, 'test2@example.com');
      expect(user.name, 'Test User 2');
      expect(user.age, 30);
      expect(user.profilePhotoUrl, 'https://example.com/photo2.jpg');
      expect(user.company, 'Test Company 2');
      expect(user.foodPreferences, ['Mexican', 'Thai']);
      expect(user.latitude, 40.7128);
      expect(user.longitude, -74.0060);
      expect(user.isVerified, false);
      expect(user.trustScore, 7.0);
      expect(user.isPremium, false);
      expect(user.referralCredits, 50.0);
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'id': 'test_user_789',
        'email': 'test3@example.com',
        'name': 'Test User 3',
        'age': 28,
        'company': 'Test Company 3',
        'foodPreferences': <String>[],
        'createdAt': '2024-01-01T00:00:00.000Z',
        'lastActive': '2024-01-02T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'test_user_789');
      expect(user.profilePhotoUrl, null);
      expect(user.latitude, null);
      expect(user.longitude, null);
      expect(user.isVerified, false);
      expect(user.trustScore, 5.0); // Default value
      expect(user.isPremium, false);
      expect(user.referralCredits, 0.0);
    });

    test('should create copy with updated fields', () {
      final updatedUser = testUser.copyWith(
        name: 'Updated Name',
        age: 26,
        isPremium: false,
      );

      expect(updatedUser.name, 'Updated Name');
      expect(updatedUser.age, 26);
      expect(updatedUser.isPremium, false);
      
      // Other fields should remain unchanged
      expect(updatedUser.id, testUser.id);
      expect(updatedUser.email, testUser.email);
      expect(updatedUser.company, testUser.company);
      expect(updatedUser.trustScore, testUser.trustScore);
    });

    test('should handle edge cases for trust score', () {
      final userWithHighScore = testUser.copyWith(trustScore: 10.0);
      final userWithLowScore = testUser.copyWith(trustScore: 0.0);

      expect(userWithHighScore.trustScore, 10.0);
      expect(userWithLowScore.trustScore, 0.0);
    });

    test('should handle empty food preferences', () {
      final userWithNoPreferences = testUser.copyWith(foodPreferences: []);
      expect(userWithNoPreferences.foodPreferences, isEmpty);
    });
  });
}