import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

class ArrivalStatusService {
  static final ArrivalStatusService _instance = ArrivalStatusService._internal();
  factory ArrivalStatusService() => _instance;
  ArrivalStatusService._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  // Share arrival status with group members
  Future<void> shareArrivalStatus({
    required String planId,
    required String userId,
    required String status, // 'on_way', 'arrived', 'delayed'
    String? message,
    int? estimatedArrivalMinutes,
  }) async {
    try {
      final arrivalUpdate = {
        'planId': planId,
        'userId': userId,
        'status': status,
        'message': message,
        'estimatedArrivalMinutes': estimatedArrivalMinutes,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add arrival status update
      await _firestoreService.addDocument('arrival_updates', arrivalUpdate);

      // Get plan details to notify other members
      final planDoc = await _firestoreService.getDocument('dining_plans', planId);
      if (planDoc.exists) {
        final planData = planDoc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(planData['memberIds'] ?? []);
        
        // Get user details for the notification
        final userDoc = await _firestoreService.getDocument('users', userId);
        final userData = userDoc.data() as Map<String, dynamic>;
        final userName = userData['name'] ?? 'Someone';

        // Notify other group members
        for (String memberId in memberIds) {
          if (memberId != userId) {
            await _notifyGroupMember(
              memberId: memberId,
              userName: userName,
              status: status,
              message: message,
              planData: planData,
            );
          }
        }
      }
    } catch (e) {
      print('Error sharing arrival status: $e');
      rethrow;
    }
  }

  // Get arrival updates for a plan
  Stream<List<Map<String, dynamic>>> getArrivalUpdates(String planId) {
    return _firestoreService.getCollectionStream(
      'arrival_updates',
      where: [
        {'field': 'planId', 'operator': '==', 'value': planId}
      ],
      orderBy: [
        {'field': 'timestamp', 'descending': true}
      ],
    ).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Update user's arrival status in the plan
  Future<void> updateUserArrivalStatus({
    required String planId,
    required String userId,
    required bool hasArrived,
  }) async {
    try {
      final planRef = _firestoreService.getDocumentReference('dining_plans', planId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final planDoc = await transaction.get(planRef);
        
        if (planDoc.exists) {
          final planData = planDoc.data() as Map<String, dynamic>;
          final arrivedMembers = Map<String, bool>.from(planData['arrivedMembers'] ?? {});
          
          arrivedMembers[userId] = hasArrived;
          
          // Check if all members have arrived
          final memberIds = List<String>.from(planData['memberIds'] ?? []);
          final allArrived = memberIds.every((memberId) => arrivedMembers[memberId] == true);
          
          final updateData = {
            'arrivedMembers': arrivedMembers,
            'lastArrivalUpdate': FieldValue.serverTimestamp(),
          };
          
          if (allArrived && planData['status'] != 'all_arrived') {
            updateData['status'] = 'all_arrived';
            updateData['allArrivedAt'] = FieldValue.serverTimestamp();
          }
          
          transaction.update(planRef, updateData);
        }
      });

      // Share arrival status with group
      await shareArrivalStatus(
        planId: planId,
        userId: userId,
        status: hasArrived ? 'arrived' : 'not_arrived',
        message: hasArrived ? 'I have arrived at the restaurant!' : 'I have not arrived yet.',
      );
    } catch (e) {
      print('Error updating arrival status: $e');
      rethrow;
    }
  }

  // Send quick status updates
  Future<void> sendQuickStatusUpdate({
    required String planId,
    required String userId,
    required String statusType, // 'on_way', 'delayed', 'parking', 'ordering'
    int? delayMinutes,
  }) async {
    String message;
    String status;
    
    switch (statusType) {
      case 'on_way':
        message = 'I\'m on my way to the restaurant!';
        status = 'on_way';
        break;
      case 'delayed':
        message = delayMinutes != null 
            ? 'I\'m running $delayMinutes minutes late. Sorry!'
            : 'I\'m running a bit late. Sorry!';
        status = 'delayed';
        break;
      case 'parking':
        message = 'I\'m here but looking for parking. Be there soon!';
        status = 'parking';
        break;
      case 'ordering':
        message = 'I\'ve arrived and I\'m ready to order!';
        status = 'arrived';
        break;
      default:
        message = 'Status update';
        status = 'update';
    }

    await shareArrivalStatus(
      planId: planId,
      userId: userId,
      status: status,
      message: message,
      estimatedArrivalMinutes: delayMinutes,
    );
  }

  // Get latest arrival status for each member
  Future<Map<String, Map<String, dynamic>>> getLatestMemberStatuses(String planId) async {
    try {
      final updatesSnapshot = await _firestoreService.getCollection(
        'arrival_updates',
        where: [
          {'field': 'planId', 'operator': '==', 'value': planId}
        ],
        orderBy: [
          {'field': 'timestamp', 'descending': true}
        ],
      );

      final Map<String, Map<String, dynamic>> latestStatuses = {};
      
      for (var doc in updatesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] as String;
        
        // Only keep the latest status for each user
        if (!latestStatuses.containsKey(userId)) {
          latestStatuses[userId] = data;
        }
      }
      
      return latestStatuses;
    } catch (e) {
      print('Error getting latest member statuses: $e');
      return {};
    }
  }

  // Private method to notify group members
  Future<void> _notifyGroupMember({
    required String memberId,
    required String userName,
    required String status,
    String? message,
    required Map<String, dynamic> planData,
  }) async {
    String notificationTitle;
    String notificationBody;
    
    switch (status) {
      case 'on_way':
        notificationTitle = '🚗 $userName is on the way';
        notificationBody = message ?? '$userName is heading to ${planData['restaurantName']}';
        break;
      case 'arrived':
        notificationTitle = '✅ $userName has arrived';
        notificationBody = message ?? '$userName is at ${planData['restaurantName']}';
        break;
      case 'delayed':
        notificationTitle = '⏰ $userName is running late';
        notificationBody = message ?? '$userName will be a bit late';
        break;
      case 'parking':
        notificationTitle = '🅿️ $userName is looking for parking';
        notificationBody = message ?? '$userName is at the location but finding parking';
        break;
      default:
        notificationTitle = '📍 Status update from $userName';
        notificationBody = message ?? 'Status update';
    }

    await _notificationService.sendNotificationToUser(
      userId: memberId,
      title: notificationTitle,
      body: notificationBody,
      data: {
        'type': 'arrival_status',
        'planId': planData['id'] ?? '',
        'fromUserId': planData['creatorId'] ?? '',
        'status': status,
      },
    );
  }

  // Clean up old arrival updates (call this periodically)
  Future<void> cleanupOldArrivalUpdates() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      final oldUpdatesSnapshot = await _firestoreService.getCollection(
        'arrival_updates',
        where: [
          {'field': 'timestamp', 'operator': '<', 'value': Timestamp.fromDate(cutoffDate)}
        ],
      );

      final batch = FirebaseFirestore.instance.batch();
      
      for (var doc in oldUpdatesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('Cleaned up ${oldUpdatesSnapshot.docs.length} old arrival updates');
    } catch (e) {
      print('Error cleaning up old arrival updates: $e');
    }
  }
}