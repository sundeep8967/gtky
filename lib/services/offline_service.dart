import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';
import '../models/dining_plan_model.dart';
import '../models/restaurant_model.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  SharedPreferences? _prefs;

  // Cache keys
  static const String _userCacheKey = 'cached_user_data';
  static const String _restaurantsCacheKey = 'cached_restaurants';
  static const String _plansCacheKey = 'cached_plans';
  static const String _pendingActionsCacheKey = 'pending_actions';
  static const String _lastSyncKey = 'last_sync_timestamp';

  // Initialize offline service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _setupConnectivityListener();
  }

  // Check if device is online
  Future<bool> isOnline() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  // Setup connectivity listener for automatic sync
  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _syncPendingActions();
      }
    });
  }

  // Cache user data
  Future<void> cacheUserData(UserModel user) async {
    try {
      await _prefs?.setString(_userCacheKey, jsonEncode(user.toJson()));
      print('User data cached successfully');
    } catch (e) {
      print('Error caching user data: $e');
    }
  }

  // Get cached user data
  Future<UserModel?> getCachedUserData() async {
    try {
      final cachedData = _prefs?.getString(_userCacheKey);
      if (cachedData != null) {
        final userData = jsonDecode(cachedData) as Map<String, dynamic>;
        return UserModel.fromJson(userData);
      }
    } catch (e) {
      print('Error getting cached user data: $e');
    }
    return null;
  }

  // Cache restaurants data
  Future<void> cacheRestaurants(List<RestaurantModel> restaurants) async {
    try {
      final restaurantsJson = restaurants.map((r) => r.toJson()).toList();
      await _prefs?.setString(_restaurantsCacheKey, jsonEncode(restaurantsJson));
      print('Restaurants cached successfully');
    } catch (e) {
      print('Error caching restaurants: $e');
    }
  }

  // Get cached restaurants
  Future<List<RestaurantModel>> getCachedRestaurants() async {
    try {
      final cachedData = _prefs?.getString(_restaurantsCacheKey);
      if (cachedData != null) {
        final restaurantsJson = jsonDecode(cachedData) as List<dynamic>;
        return restaurantsJson
            .map((json) => RestaurantModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting cached restaurants: $e');
    }
    return [];
  }

  // Cache dining plans
  Future<void> cacheDiningPlans(List<DiningPlanModel> plans) async {
    try {
      final plansJson = plans.map((p) => p.toJson()).toList();
      await _prefs?.setString(_plansCacheKey, jsonEncode(plansJson));
      print('Dining plans cached successfully');
    } catch (e) {
      print('Error caching dining plans: $e');
    }
  }

  // Get cached dining plans
  Future<List<DiningPlanModel>> getCachedDiningPlans() async {
    try {
      final cachedData = _prefs?.getString(_plansCacheKey);
      if (cachedData != null) {
        final plansJson = jsonDecode(cachedData) as List<dynamic>;
        return plansJson
            .map((json) => DiningPlanModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting cached dining plans: $e');
    }
    return [];
  }

  // Add pending action for later sync
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    try {
      final pendingActions = await _getPendingActions();
      action['timestamp'] = DateTime.now().toIso8601String();
      action['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      
      pendingActions.add(action);
      await _prefs?.setString(_pendingActionsCacheKey, jsonEncode(pendingActions));
      
      print('Pending action added: ${action['type']}');
    } catch (e) {
      print('Error adding pending action: $e');
    }
  }

  // Get pending actions
  Future<List<Map<String, dynamic>>> _getPendingActions() async {
    try {
      final cachedData = _prefs?.getString(_pendingActionsCacheKey);
      if (cachedData != null) {
        final actionsJson = jsonDecode(cachedData) as List<dynamic>;
        return actionsJson.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting pending actions: $e');
    }
    return [];
  }

  // Sync pending actions when online
  Future<void> _syncPendingActions() async {
    try {
      final pendingActions = await _getPendingActions();
      if (pendingActions.isEmpty) return;

      print('Syncing ${pendingActions.length} pending actions...');

      final successfulActions = <String>[];

      for (final action in pendingActions) {
        try {
          final success = await _processPendingAction(action);
          if (success) {
            successfulActions.add(action['id']);
          }
        } catch (e) {
          print('Error processing action ${action['id']}: $e');
        }
      }

      // Remove successfully synced actions
      if (successfulActions.isNotEmpty) {
        final remainingActions = pendingActions
            .where((action) => !successfulActions.contains(action['id']))
            .toList();
        
        await _prefs?.setString(_pendingActionsCacheKey, jsonEncode(remainingActions));
        print('Synced ${successfulActions.length} actions successfully');
      }

      // Update last sync timestamp
      await _prefs?.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
    } catch (e) {
      print('Error syncing pending actions: $e');
    }
  }

  // Process individual pending action
  Future<bool> _processPendingAction(Map<String, dynamic> action) async {
    try {
      switch (action['type']) {
        case 'create_plan':
          return await _syncCreatePlan(action);
        case 'join_plan':
          return await _syncJoinPlan(action);
        case 'update_profile':
          return await _syncUpdateProfile(action);
        case 'submit_rating':
          return await _syncSubmitRating(action);
        default:
          print('Unknown action type: ${action['type']}');
          return false;
      }
    } catch (e) {
      print('Error processing action: $e');
      return false;
    }
  }

  // Sync create plan action
  Future<bool> _syncCreatePlan(Map<String, dynamic> action) async {
    // Implementation would call the actual dining plan service
    // For now, we'll simulate success
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Sync join plan action
  Future<bool> _syncJoinPlan(Map<String, dynamic> action) async {
    // Implementation would call the actual dining plan service
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Sync update profile action
  Future<bool> _syncUpdateProfile(Map<String, dynamic> action) async {
    // Implementation would call the actual user service
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Sync submit rating action
  Future<bool> _syncSubmitRating(Map<String, dynamic> action) async {
    // Implementation would call the actual rating service
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final lastSyncString = _prefs?.getString(_lastSyncKey);
      if (lastSyncString != null) {
        return DateTime.parse(lastSyncString);
      }
    } catch (e) {
      print('Error getting last sync time: $e');
    }
    return null;
  }

  // Force sync all pending actions
  Future<void> forceSyncAll() async {
    final isConnected = await isOnline();
    if (isConnected) {
      await _syncPendingActions();
    } else {
      throw Exception('No internet connection available');
    }
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      await _prefs?.remove(_userCacheKey);
      await _prefs?.remove(_restaurantsCacheKey);
      await _prefs?.remove(_plansCacheKey);
      await _prefs?.remove(_pendingActionsCacheKey);
      await _prefs?.remove(_lastSyncKey);
      
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Get cache size information
  Future<Map<String, int>> getCacheInfo() async {
    try {
      final userCache = _prefs?.getString(_userCacheKey)?.length ?? 0;
      final restaurantsCache = _prefs?.getString(_restaurantsCacheKey)?.length ?? 0;
      final plansCache = _prefs?.getString(_plansCacheKey)?.length ?? 0;
      final pendingActions = (await _getPendingActions()).length;

      return {
        'userCacheSize': userCache,
        'restaurantsCacheSize': restaurantsCache,
        'plansCacheSize': plansCache,
        'pendingActionsCount': pendingActions,
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {};
    }
  }

  // Check if data is stale (older than specified duration)
  bool isDataStale(DateTime? lastUpdate, Duration maxAge) {
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate) > maxAge;
  }
}