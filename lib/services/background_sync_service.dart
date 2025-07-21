import 'dart:async';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_service.dart';
import 'notification_service.dart';

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  Timer? _syncTimer;
  final OfflineService _offlineService = OfflineService();
  final NotificationService _notificationService = NotificationService();

  // Sync intervals
  static const Duration _quickSyncInterval = Duration(minutes: 5);
  static const Duration _regularSyncInterval = Duration(minutes: 15);
  static const Duration _backgroundSyncInterval = Duration(hours: 1);

  bool _isInitialized = false;
  bool _isSyncing = false;

  // Initialize background sync
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _offlineService.initialize();
      _startPeriodicSync();
      _isInitialized = true;
      
      print('Background sync service initialized');
    } catch (e) {
      print('Error initializing background sync: $e');
    }
  }

  // Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    
    _syncTimer = Timer.periodic(_regularSyncInterval, (timer) {
      _performBackgroundSync();
    });
  }

  // Perform background sync
  Future<void> _performBackgroundSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    
    try {
      final isOnline = await _offlineService.isOnline();
      
      if (isOnline) {
        await _syncAllData();
        await _sendSyncNotificationIfNeeded();
      } else {
        print('Device offline - skipping sync');
      }
    } catch (e) {
      print('Error during background sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Sync all data types
  Future<void> _syncAllData() async {
    try {
      // Sync pending actions first
      await _offlineService.forceSyncAll();
      
      // Sync fresh data from server
      await _syncUserData();
      await _syncRestaurantData();
      await _syncDiningPlansData();
      await _syncNotifications();
      
      print('Background sync completed successfully');
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  // Sync user data
  Future<void> _syncUserData() async {
    try {
      // In a real app, this would fetch fresh user data from the server
      // For now, we'll simulate the process
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Cache the updated user data
      // final userData = await userService.getCurrentUser();
      // await _offlineService.cacheUserData(userData);
      
      print('User data synced');
    } catch (e) {
      print('Error syncing user data: $e');
    }
  }

  // Sync restaurant data
  Future<void> _syncRestaurantData() async {
    try {
      // Fetch fresh restaurant data
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Cache the updated restaurant data
      // final restaurants = await restaurantService.getAllRestaurants();
      // await _offlineService.cacheRestaurants(restaurants);
      
      print('Restaurant data synced');
    } catch (e) {
      print('Error syncing restaurant data: $e');
    }
  }

  // Sync dining plans data
  Future<void> _syncDiningPlansData() async {
    try {
      // Fetch fresh dining plans
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Cache the updated plans
      // final plans = await diningPlanService.getUserPlans();
      // await _offlineService.cacheDiningPlans(plans);
      
      print('Dining plans synced');
    } catch (e) {
      print('Error syncing dining plans: $e');
    }
  }

  // Sync notifications
  Future<void> _syncNotifications() async {
    try {
      // Fetch and process new notifications
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Process any new notifications
      // final notifications = await notificationService.getNewNotifications();
      // for (final notification in notifications) {
      //   await _notificationService.showLocalNotification(notification);
      // }
      
      print('Notifications synced');
    } catch (e) {
      print('Error syncing notifications: $e');
    }
  }

  // Send sync notification if needed
  Future<void> _sendSyncNotificationIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotificationTime = prefs.getString('last_sync_notification');
      final now = DateTime.now();
      
      // Send notification only once per day
      if (lastNotificationTime == null || 
          now.difference(DateTime.parse(lastNotificationTime)).inDays >= 1) {
        
        // await _notificationService.createNotification(
        //   userId: 'current_user', // Replace with actual user ID
        //   type: NotificationType.systemUpdate,
        //   title: 'Data Synced',
        //   body: 'Your GTKY data has been updated with the latest information.',
        //   priority: NotificationPriority.low,
        // );
        
        await prefs.setString('last_sync_notification', now.toIso8601String());
      }
    } catch (e) {
      print('Error sending sync notification: $e');
    }
  }

  // Force immediate sync
  Future<void> forceSync() async {
    if (_isSyncing) {
      print('Sync already in progress');
      return;
    }

    await _performBackgroundSync();
  }

  // Schedule quick sync (for immediate actions)
  void scheduleQuickSync() {
    Timer(_quickSyncInterval, () {
      _performBackgroundSync();
    });
  }

  // Pause background sync
  void pauseSync() {
    _syncTimer?.cancel();
    print('Background sync paused');
  }

  // Resume background sync
  void resumeSync() {
    if (_isInitialized) {
      _startPeriodicSync();
      print('Background sync resumed');
    }
  }

  // Update sync interval based on app state
  void updateSyncInterval({required bool isAppActive}) {
    _syncTimer?.cancel();
    
    final interval = isAppActive ? _regularSyncInterval : _backgroundSyncInterval;
    
    _syncTimer = Timer.periodic(interval, (timer) {
      _performBackgroundSync();
    });
    
    print('Sync interval updated: ${interval.inMinutes} minutes');
  }

  // Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isInitialized': _isInitialized,
      'isSyncing': _isSyncing,
      'syncInterval': _syncTimer?.isActive == true 
          ? _regularSyncInterval.inMinutes 
          : 0,
      'lastSyncTime': DateTime.now().toIso8601String(), // Would be actual last sync time
    };
  }

  // Clean up resources
  void dispose() {
    _syncTimer?.cancel();
    _isInitialized = false;
    _isSyncing = false;
    print('Background sync service disposed');
  }
}

// Background isolate entry point
@pragma('vm:entry-point')
void backgroundSyncIsolate(SendPort sendPort) {
  // This would be used for true background processing
  // when the app is completely closed
  
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  
  receivePort.listen((message) async {
    if (message == 'sync') {
      try {
        // Perform background sync operations
        await _performIsolateSync();
        sendPort.send('sync_complete');
      } catch (e) {
        sendPort.send('sync_error: $e');
      }
    }
  });
}

// Perform sync in isolate
Future<void> _performIsolateSync() async {
  try {
    // Initialize services in isolate
    final offlineService = OfflineService();
    await offlineService.initialize();
    
    // Check connectivity
    final isOnline = await offlineService.isOnline();
    
    if (isOnline) {
      // Sync pending actions
      await offlineService.forceSyncAll();
      print('Isolate sync completed');
    }
  } catch (e) {
    print('Error in isolate sync: $e');
  }
}

// Sync priority levels
enum SyncPriority {
  low,     // Background sync
  normal,  // Regular sync
  high,    // User-initiated sync
  urgent,  // Critical data sync
}

// Sync result
class SyncResult {
  final bool success;
  final String? error;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  SyncResult({
    required this.success,
    this.error,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}