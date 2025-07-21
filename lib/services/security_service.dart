import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Email verification
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('Email verification sent');
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending email verification: $e');
      return false;
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Phone number verification (placeholder for future implementation)
  Future<bool> sendPhoneVerification(String phoneNumber) async {
    try {
      // In a real app, you would use Firebase Phone Auth
      // For now, we'll simulate the process
      print('Phone verification would be sent to: $phoneNumber');
      
      // Store phone number for verification
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).update({
          'phoneNumber': phoneNumber,
          'phoneVerified': false,
          'phoneVerificationSentAt': DateTime.now().toIso8601String(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error sending phone verification: $e');
      return false;
    }
  }

  // Verify phone number with code
  Future<bool> verifyPhoneCode(String code) async {
    try {
      // In a real app, you would verify the code with Firebase
      // For now, we'll simulate verification
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).update({
          'phoneVerified': true,
          'phoneVerifiedAt': DateTime.now().toIso8601String(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying phone code: $e');
      return false;
    }
  }

  // Company domain verification
  Future<bool> verifyCompanyDomain(String email, String company) async {
    try {
      final domain = email.split('@').last.toLowerCase();
      final companyName = company.toLowerCase().replaceAll(' ', '');
      
      // List of known company domains (in a real app, this would be a comprehensive database)
      final Map<String, List<String>> companyDomains = {
        'google': ['google.com', 'gmail.com'],
        'microsoft': ['microsoft.com', 'outlook.com'],
        'apple': ['apple.com', 'icloud.com'],
        'amazon': ['amazon.com'],
        'meta': ['meta.com', 'facebook.com'],
        'netflix': ['netflix.com'],
        'uber': ['uber.com'],
        'airbnb': ['airbnb.com'],
        'spotify': ['spotify.com'],
        'linkedin': ['linkedin.com'],
        'twitter': ['twitter.com'],
        'snapchat': ['snapchat.com'],
        'tiktok': ['tiktok.com'],
        'zoom': ['zoom.us'],
        'slack': ['slack.com'],
        'dropbox': ['dropbox.com'],
        'salesforce': ['salesforce.com'],
        'adobe': ['adobe.com'],
        'intel': ['intel.com'],
        'nvidia': ['nvidia.com'],
      };

      // Check if domain matches company
      final domains = companyDomains[companyName];
      if (domains != null && domains.contains(domain)) {
        // Update user verification status
        final user = _auth.currentUser;
        if (user != null) {
          await _db.collection('users').doc(user.uid).update({
            'companyVerified': true,
            'companyVerifiedAt': DateTime.now().toIso8601String(),
            'verificationMethod': 'domain',
          });
        }
        return true;
      }

      // For other companies, mark as pending manual verification
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).update({
          'companyVerified': false,
          'companyVerificationPending': true,
          'companyVerificationRequestedAt': DateTime.now().toIso8601String(),
        });
      }

      return false;
    } catch (e) {
      print('Error verifying company domain: $e');
      return false;
    }
  }

  // Generate secure random password
  String generateSecurePassword({int length = 12}) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final Random random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Hash sensitive data
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // User behavior monitoring
  Future<void> logUserActivity({
    required String userId,
    required String activity,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _db.collection('user_activity').add({
        'userId': userId,
        'activity': activity,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'ipAddress': 'unknown', // In a real app, you'd get the actual IP
        'userAgent': 'mobile_app',
      });
    } catch (e) {
      print('Error logging user activity: $e');
    }
  }

  // Check for suspicious activity
  Future<bool> checkSuspiciousActivity(String userId) async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));

      // Check for too many login attempts
      final loginAttempts = await _db.collection('user_activity')
          .where('userId', isEqualTo: userId)
          .where('activity', isEqualTo: 'login_attempt')
          .where('timestamp', isGreaterThan: oneHourAgo.toIso8601String())
          .get();

      if (loginAttempts.docs.length > 10) {
        return true; // Suspicious: too many login attempts
      }

      // Check for rapid location changes
      final locationChanges = await _db.collection('user_activity')
          .where('userId', isEqualTo: userId)
          .where('activity', isEqualTo: 'location_update')
          .where('timestamp', isGreaterThan: oneHourAgo.toIso8601String())
          .get();

      if (locationChanges.docs.length > 5) {
        return true; // Suspicious: rapid location changes
      }

      return false;
    } catch (e) {
      print('Error checking suspicious activity: $e');
      return false;
    }
  }

  // Account security score
  Future<double> calculateSecurityScore(String userId) async {
    try {
      double score = 0.0;
      
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0.0;
      
      final userData = userDoc.data()!;

      // Email verification (20 points)
      if (userData['emailVerified'] == true) score += 20;

      // Phone verification (15 points)
      if (userData['phoneVerified'] == true) score += 15;

      // Company verification (20 points)
      if (userData['companyVerified'] == true) score += 20;

      // Profile completeness (15 points)
      if (userData['profilePhotoUrl'] != null) score += 5;
      if (userData['name'] != null && userData['name'].toString().isNotEmpty) score += 5;
      if (userData['foodPreferences'] != null && (userData['foodPreferences'] as List).isNotEmpty) score += 5;

      // Trust score (20 points)
      final trustScore = userData['trustScore']?.toDouble() ?? 5.0;
      score += (trustScore / 10.0) * 20;

      // No recent suspicious activity (10 points)
      final hasSuspiciousActivity = await checkSuspiciousActivity(userId);
      if (!hasSuspiciousActivity) score += 10;

      return score.clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating security score: $e');
      return 0.0;
    }
  }

  // Get security recommendations
  Future<List<String>> getSecurityRecommendations(String userId) async {
    try {
      final recommendations = <String>[];
      
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return recommendations;
      
      final userData = userDoc.data()!;

      if (userData['emailVerified'] != true) {
        recommendations.add('Verify your email address for better security');
      }

      if (userData['phoneVerified'] != true) {
        recommendations.add('Add and verify your phone number');
      }

      if (userData['companyVerified'] != true) {
        recommendations.add('Verify your company affiliation');
      }

      if (userData['profilePhotoUrl'] == null) {
        recommendations.add('Add a profile photo to build trust');
      }

      final trustScore = userData['trustScore']?.toDouble() ?? 5.0;
      if (trustScore < 7.0) {
        recommendations.add('Complete more dining plans to improve your trust score');
      }

      if (recommendations.isEmpty) {
        recommendations.add('Your account security is excellent! 🎉');
      }

      return recommendations;
    } catch (e) {
      print('Error getting security recommendations: $e');
      return ['Unable to load security recommendations'];
    }
  }
}