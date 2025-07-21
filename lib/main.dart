import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/navigation/app_navigation.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';
import 'utils/logger.dart';
import 'utils/crashlytics_service.dart';
import 'utils/analytics_service.dart';
import 'utils/performance_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Track app startup performance
  PerformanceMonitor.trackAppStartup();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  Logger.info('Firebase initialized successfully');
  
  // Initialize production services
  await CrashlyticsService().initialize();
  await AnalyticsService().initialize();
  
  // Set iOS-style system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize notification service
  await NotificationService().initialize();
  
  // Start performance monitoring
  PerformanceMonitor().monitorFramePerformance();
  
  Logger.info('GTKY App initialization complete');
  runApp(const GTKYApp());
}

class GTKYApp extends StatelessWidget {
  const GTKYApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'GTKY - Get To Know You',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: AppNavigation.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
