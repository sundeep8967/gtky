import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/blocked_user_model.dart';

class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;
  SafetyService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _reports => _db.collection('reports');
  CollectionReference get _blockedUsers => _db.collection('blocked_users');
  CollectionReference get _users => _db.collection('users');

  // Report reasons
  static const List<String> reportReasons = [
    'Inappropriate behavior',
    'Harassment',
    'Fake profile',
    'No-show',
    'Spam',
    'Safety concern',
    'Other',
  ];

  // Report a user
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      final reportId = _reports.doc().id;
      final report = ReportModel(
        id: reportId,
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        createdAt: DateTime.now(),
      );

      await _reports.doc(reportId).set(report.toJson());
      
      // Update reported user's trust score
      await _updateTrustScore(reportedUserId, -0.5);
      
      print('User reported successfully');
    } catch (e) {
      print('Error reporting user: $e');
      throw Exception('Failed to report user');
    }
  }

  // Block a user
  Future<void> blockUser({
    required String blockerId,
    required String blockedUserId,
    String? reason,
  }) async {
    try {
      final blockId = _blockedUsers.doc().id;
      final block = BlockedUserModel(
        id: blockId,
        blockerId: blockerId,
        blockedUserId: blockedUserId,
        createdAt: DateTime.now(),
        reason: reason,
      );

      await _blockedUsers.doc(blockId).set(block.toJson());
      print('User blocked successfully');
    } catch (e) {
      print('Error blocking user: $e');
      throw Exception('Failed to block user');
    }
  }

  // Unblock a user
  Future<void> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      final query = await _blockedUsers
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .get();

      for (var doc in query.docs) {
        await doc.reference.delete();
      }
      
      print('User unblocked successfully');
    } catch (e) {
      print('Error unblocking user: $e');
      throw Exception('Failed to unblock user');
    }
  }

  // Check if user is blocked
  Future<bool> isUserBlocked({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      final query = await _blockedUsers
          .where('blockerId', isEqualTo: blockerId)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Get blocked users for a user
  Future<List<BlockedUserModel>> getBlockedUsers(String userId) async {
    try {
      final query = await _blockedUsers
          .where('blockerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => BlockedUserModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting blocked users: $e');
      return [];
    }
  }

  // Get reports made by a user
  Future<List<ReportModel>> getUserReports(String userId) async {
    try {
      final query = await _reports
          .where('reporterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ReportModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user reports: $e');
      return [];
    }
  }

  // Check if users can interact (not blocked by each other)
  Future<bool> canUsersInteract(String userId1, String userId2) async {
    try {
      // Check if user1 blocked user2
      final blocked1 = await isUserBlocked(
        blockerId: userId1,
        blockedUserId: userId2,
      );

      // Check if user2 blocked user1
      final blocked2 = await isUserBlocked(
        blockerId: userId2,
        blockedUserId: userId1,
      );

      return !blocked1 && !blocked2;
    } catch (e) {
      print('Error checking user interaction: $e');
      return true; // Default to allowing interaction if check fails
    }
  }

  // Update user trust score
  Future<void> _updateTrustScore(String userId, double change) async {
    try {
      final userDoc = await _users.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final currentScore = userData['trustScore']?.toDouble() ?? 5.0;
        final newScore = (currentScore + change).clamp(0.0, 10.0);
        
        await _users.doc(userId).update({'trustScore': newScore});
      }
    } catch (e) {
      print('Error updating trust score: $e');
    }
  }

  // Get safety guidelines
  List<String> getSafetyGuidelines() {
    return [
      'Meet in public places only',
      'Share your plans with a friend',
      'Trust your instincts',
      'Don\'t share personal information too quickly',
      'Report any inappropriate behavior',
      'Use the app\'s messaging system initially',
      'Verify the restaurant location before meeting',
      'Keep emergency contacts handy',
    ];
  }

  // Get emergency contacts info
  Map<String, String> getEmergencyContacts() {
    return {
      'Police': '100',
      'Women Helpline': '1091',
      'Emergency': '112',
      'Cyber Crime': '1930',
    };
  }
}