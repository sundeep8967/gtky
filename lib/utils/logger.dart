import 'package:flutter/foundation.dart';

/// Production-ready logging utility to replace print statements
class Logger {
  static const String _tag = 'GTKY';
  
  /// Log debug information (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      print('🐛 $_tag${tag != null ? '[$tag]' : ''}: $message');
    }
  }
  
  /// Log general information
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      print('ℹ️ $_tag${tag != null ? '[$tag]' : ''}: $message');
    }
  }
  
  /// Log warnings
  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      print('⚠️ $_tag${tag != null ? '[$tag]' : ''}: $message');
    }
  }
  
  /// Log errors (always logged, even in release)
  static void error(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    print('❌ $_tag${tag != null ? '[$tag]' : ''}: $message');
    if (error != null) {
      print('Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      print('Stack trace: $stackTrace');
    }
  }
  
  /// Log network requests
  static void network(String method, String url, [int? statusCode]) {
    if (kDebugMode) {
      print('🌐 $_tag[Network]: $method $url${statusCode != null ? ' ($statusCode)' : ''}');
    }
  }
  
  /// Log authentication events
  static void auth(String message) {
    if (kDebugMode) {
      print('🔐 $_tag[Auth]: $message');
    }
  }
  
  /// Log database operations
  static void database(String operation, [String? collection]) {
    if (kDebugMode) {
      print('🗄️ $_tag[DB]: $operation${collection != null ? ' ($collection)' : ''}');
    }
  }
  
  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    if (kDebugMode) {
      print('⚡ $_tag[Performance]: $operation took ${duration.inMilliseconds}ms');
    }
  }
}