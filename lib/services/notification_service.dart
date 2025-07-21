import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/dining_plan_model.dart';
import '../models/restaurant_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _notifications => _db.collection('notifications');
  CollectionReference get _userTokens => _db.collection('user_tokens');

  // Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
        
        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          print('FCM Token: $token');
          // Store token for current user (implement when user is available)
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((String token) {
          print('FCM Token refreshed: $token');
          // Update token in database
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background message taps
        FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

        // Handle app launch from notification
        RemoteMessage? initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessageTap(initialMessage);
        }
      }
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Store user FCM token
  Future<void> storeUserToken(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _userTokens.doc(userId).set({
          'token': token,
          'updatedAt': DateTime.now().toIso8601String(),
          'platform': Theme.of(NavigationService.navigatorKey.currentContext!).platform.name,
        });
      }
    } catch (e) {
      print('Error storing user token: $e');
    }
  }

  // Create and store notification
  Future<NotificationModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    NotificationPriority priority = NotificationPriority.normal,
    DateTime? scheduledFor,
    String? actionUrl,
    String? imageUrl,
  }) async {
    try {
      final notificationId = _notifications.doc().id;
      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
        priority: priority,
        createdAt: DateTime.now(),
        scheduledFor: scheduledFor,
        actionUrl: actionUrl,
        imageUrl: imageUrl,
      );

      await _notifications.doc(notificationId).set(notification.toJson());

      // Send immediately if not scheduled
      if (scheduledFor == null || scheduledFor.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
        await _sendNotificationToUser(userId, notification);
      }

      return notification;
    } catch (e) {
      print('Error creating notification: $e');
      throw Exception('Failed to create notification');
    }
  }

  // Send match found notification
  Future<void> sendMatchFoundNotification({
    required String userId,
    required DiningPlanModel plan,
    required RestaurantModel restaurant,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.matchFound,
      title: '🎉 Match Found!',
      body: 'Your dining plan at ${restaurant.name} is now full. Get ready to meet new people!',
      data: {
        'planId': plan.id,
        'restaurantId': restaurant.id,
        'plannedTime': plan.plannedTime.toIso8601String(),
      },
      priority: NotificationPriority.high,
      actionUrl: '/plan-details/${plan.id}',
    );
  }

  // Send arrival reminder
  Future<void> sendArrivalReminder({
    required String userId,
    required DiningPlanModel plan,
    required RestaurantModel restaurant,
  }) async {
    final reminderTime = plan.plannedTime.subtract(const Duration(minutes: 15));
    
    await createNotification(
      userId: userId,
      type: NotificationType.arrivalReminder,
      title: '⏰ Time to head out!',
      body: 'Your dining plan at ${restaurant.name} starts in 15 minutes. Don\'t keep your group waiting!',
      data: {
        'planId': plan.id,
        'restaurantId': restaurant.id,
        'plannedTime': plan.plannedTime.toIso8601String(),
      },
      priority: NotificationPriority.high,
      scheduledFor: reminderTime,
      actionUrl: '/plan-details/${plan.id}',
    );
  }

  // Send rating reminder
  Future<void> sendRatingReminder({
    required String userId,
    required DiningPlanModel plan,
    required RestaurantModel restaurant,
  }) async {
    final reminderTime = plan.plannedTime.add(const Duration(hours: 2));
    
    await createNotification(
      userId: userId,
      type: NotificationType.ratingReminder,
      title: '⭐ How was your experience?',
      body: 'Please rate your dining experience at ${restaurant.name} and help others discover great places!',
      data: {
        'planId': plan.id,
        'restaurantId': restaurant.id,
      },
      priority: NotificationPriority.normal,
      scheduledFor: reminderTime,
      actionUrl: '/rate-experience/${plan.id}',
    );
  }

  // Send new restaurant notification
  Future<void> sendNewRestaurantNotification({
    required String userId,
    required RestaurantModel restaurant,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.newRestaurant,
      title: '🍽️ New Restaurant Added!',
      body: '${restaurant.name} just joined GTKY! Check out their ${restaurant.discountPercentage}% discount.',
      data: {
        'restaurantId': restaurant.id,
      },
      priority: NotificationPriority.normal,
      actionUrl: '/restaurant-details/${restaurant.id}',
      imageUrl: restaurant.imageUrl,
    );
  }

  // Send plan update notification
  Future<void> sendPlanUpdateNotification({
    required String userId,
    required String title,
    required String body,
    required String planId,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.planUpdate,
      title: title,
      body: body,
      data: {'planId': planId},
      priority: priority,
      actionUrl: '/plan-details/$planId',
    );
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      final query = await _notifications
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => NotificationModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    try {
      final query = await _notifications
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final query = await _notifications
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return query.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Private methods
  Future<void> _sendNotificationToUser(String userId, NotificationModel notification) async {
    try {
      // Get user's FCM token
      final tokenDoc = await _userTokens.doc(userId).get();
      if (!tokenDoc.exists) return;

      final tokenData = tokenDoc.data() as Map<String, dynamic>;
      final token = tokenData['token'] as String?;
      if (token == null) return;

      // Send FCM message (in a real app, this would be done via Cloud Functions)
      print('Sending notification to token: $token');
      print('Title: ${notification.title}');
      print('Body: ${notification.body}');

      // Mark as sent
      await _notifications.doc(notification.id).update({
        'isSent': true,
        'sentAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending notification to user: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    
    // Show in-app notification or update UI
    // You could use a package like flutter_local_notifications for this
  }

  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    
    // Navigate to appropriate screen based on message data
    final data = message.data;
    if (data.containsKey('actionUrl')) {
      // Navigate to the specified URL
      print('Navigating to: ${data['actionUrl']}');
    }
  }
}

// Navigation service for global context access
class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}