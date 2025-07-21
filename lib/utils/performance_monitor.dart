import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'logger.dart';
import 'analytics_service.dart';

/// Performance monitoring utility for production optimization
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _operationStartTimes = {};
  final AnalyticsService _analytics = AnalyticsService();

  /// Start timing an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    Logger.performance('Started operation: $operationName', Duration.zero);
  }

  /// End timing an operation and log the duration
  Duration endOperation(String operationName) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      Logger.warning('Operation $operationName was not started');
      return Duration.zero;
    }

    final duration = DateTime.now().difference(startTime);
    Logger.performance('Completed operation: $operationName', duration);
    
    // Track in analytics if duration is significant
    if (duration.inMilliseconds > 100) {
      _analytics.trackPerformance(operationName, duration);
    }

    return duration;
  }

  /// Measure and execute a function with performance tracking
  static Future<T> measure<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final monitor = PerformanceMonitor();
    monitor.startOperation(operationName);
    
    try {
      final result = await operation();
      monitor.endOperation(operationName);
      return result;
    } catch (e) {
      monitor.endOperation(operationName);
      Logger.error('Operation $operationName failed', 'Performance', e);
      rethrow;
    }
  }

  /// Measure synchronous operations
  static T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    final monitor = PerformanceMonitor();
    monitor.startOperation(operationName);
    
    try {
      final result = operation();
      monitor.endOperation(operationName);
      return result;
    } catch (e) {
      monitor.endOperation(operationName);
      Logger.error('Sync operation $operationName failed', 'Performance', e);
      rethrow;
    }
  }

  /// Monitor memory usage (Android/iOS specific)
  Future<Map<String, dynamic>> getMemoryInfo() async {
    if (!kReleaseMode) {
      try {
        // This would require platform-specific implementation
        const platform = MethodChannel('gtky/performance');
        final result = await platform.invokeMethod('getMemoryInfo');
        return Map<String, dynamic>.from(result);
      } catch (e) {
        Logger.debug('Memory info not available: $e');
        return {};
      }
    }
    return {};
  }

  /// Monitor frame rendering performance
  void monitorFramePerformance() {
    if (kDebugMode) {
      // Monitor frame rendering in debug mode
      WidgetsBinding.instance.addTimingsCallback((timings) {
        for (final timing in timings) {
          final frameDuration = timing.totalSpan;
          if (frameDuration.inMilliseconds > 16) { // 60fps = 16.67ms per frame
            Logger.warning(
              'Slow frame detected: ${frameDuration.inMilliseconds}ms',
              'Performance',
            );
          }
        }
      });
    }
  }

  /// Track app startup time
  static void trackAppStartup() {
    final startTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final startupDuration = DateTime.now().difference(startTime);
      Logger.performance('App startup completed', startupDuration);
      AnalyticsService().trackPerformance('app_startup', startupDuration);
    });
  }

  /// Monitor network request performance
  Future<T> monitorNetworkRequest<T>(
    String requestName,
    Future<T> Function() request,
  ) async {
    return await measure('network_$requestName', request);
  }

  /// Monitor database operation performance
  Future<T> monitorDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    return await measure('db_$operationName', operation);
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'active_operations': _operationStartTimes.keys.toList(),
      'timestamp': DateTime.now().toIso8601String(),
      'debug_mode': kDebugMode,
      'release_mode': kReleaseMode,
    };
  }
}