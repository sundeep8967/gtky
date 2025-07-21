import 'package:flutter/foundation.dart';
import 'logger.dart';

/// Crashlytics service for production error reporting
/// Note: Firebase Crashlytics dependency would need to be added to pubspec.yaml
class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  /// Initialize crashlytics (placeholder for Firebase Crashlytics)
  Future<void> initialize() async {
    if (kReleaseMode) {
      // TODO: Initialize Firebase Crashlytics
      // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      Logger.info('Crashlytics initialized for production');
    } else {
      Logger.debug('Crashlytics disabled in debug mode');
    }
  }

  /// Record a non-fatal error
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? additionalData,
  }) async {
    if (kReleaseMode) {
      // TODO: Send to Firebase Crashlytics
      // await FirebaseCrashlytics.instance.recordError(
      //   exception,
      //   stackTrace,
      //   reason: reason,
      //   information: additionalData?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
      // );
    }
    
    // Always log locally
    Logger.error(
      'Recorded error: ${reason ?? exception.toString()}',
      'Crashlytics',
      exception,
      stackTrace,
    );
  }

  /// Record a fatal error
  Future<void> recordFatalError(
    dynamic exception,
    StackTrace stackTrace, {
    String? reason,
  }) async {
    if (kReleaseMode) {
      // TODO: Send to Firebase Crashlytics
      // await FirebaseCrashlytics.instance.recordError(
      //   exception,
      //   stackTrace,
      //   reason: reason,
      //   fatal: true,
      // );
    }
    
    Logger.error(
      'Fatal error: ${reason ?? exception.toString()}',
      'Crashlytics',
      exception,
      stackTrace,
    );
  }

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    if (kReleaseMode) {
      // TODO: Set user ID in Firebase Crashlytics
      // await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
    Logger.debug('User ID set for crash reporting: $userId');
  }

  /// Set custom key-value data for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    if (kReleaseMode) {
      // TODO: Set custom key in Firebase Crashlytics
      // await FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
    Logger.debug('Custom key set: $key = $value');
  }

  /// Log a message that will be included in crash reports
  Future<void> log(String message) async {
    if (kReleaseMode) {
      // TODO: Log to Firebase Crashlytics
      // await FirebaseCrashlytics.instance.log(message);
    }
    Logger.info(message, 'Crashlytics');
  }
}