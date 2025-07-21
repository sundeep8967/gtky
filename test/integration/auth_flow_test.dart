import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gtky/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    testWidgets('Complete authentication flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify initial screen is displayed
      expect(find.text('Welcome to GTKY'), findsOneWidget);

      // Test Google Sign-In button exists
      expect(find.text('Continue with Google'), findsOneWidget);

      // Test LinkedIn verification flow
      expect(find.text('Verify with LinkedIn'), findsOneWidget);

      // Note: Actual authentication testing would require mock services
      // or test accounts, which is beyond the scope of this demo
    });

    testWidgets('Profile setup flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile setup (assuming user is authenticated)
      // This would typically be done after successful authentication

      // Test profile form fields
      await tester.enterText(find.byType(TextFormField).first, 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), '25');
      await tester.enterText(find.byType(TextFormField).at(2), 'Test Company');

      // Test food preference selection
      await tester.tap(find.text('Italian'));
      await tester.tap(find.text('Chinese'));

      // Test form validation
      await tester.tap(find.text('Complete Profile'));
      await tester.pumpAndSettle();

      // Verify validation messages or success
      // Implementation depends on actual form validation
    });

    testWidgets('Navigation flow test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test bottom navigation
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Test tab navigation
      await tester.tap(find.text('Join Plans'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('My Plans'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify each screen loads correctly
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Restaurant Discovery Integration Tests', () {
    testWidgets('Restaurant list and search', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to restaurant discovery
      await tester.tap(find.text('Restaurants'));
      await tester.pumpAndSettle();

      // Test search functionality
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'Pizza');
        await tester.pumpAndSettle();
      }

      // Test restaurant card interactions
      final restaurantCards = find.byType(Card);
      if (restaurantCards.evaluate().isNotEmpty) {
        await tester.tap(restaurantCards.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Plan creation flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to create plan
      final createPlanButton = find.text('Create Plan');
      if (createPlanButton.evaluate().isNotEmpty) {
        await tester.tap(createPlanButton);
        await tester.pumpAndSettle();

        // Test plan creation form
        // Implementation depends on actual form structure
      }
    });
  });

  group('Premium Features Integration Tests', () {
    testWidgets('Premium upgrade flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to premium upgrade
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      final premiumButton = find.text('GTKY Premium');
      if (premiumButton.evaluate().isNotEmpty) {
        await tester.tap(premiumButton);
        await tester.pumpAndSettle();

        // Test premium features display
        expect(find.text('Premium Features'), findsOneWidget);
        expect(find.text('₹199'), findsOneWidget);
      }
    });

    testWidgets('Referral system flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to referrals
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      final referralButton = find.text('Referrals & Rewards');
      if (referralButton.evaluate().isNotEmpty) {
        await tester.tap(referralButton);
        await tester.pumpAndSettle();

        // Test referral code generation
        final generateButton = find.text('Generate Referral Code');
        if (generateButton.evaluate().isNotEmpty) {
          await tester.tap(generateButton);
          await tester.pumpAndSettle();
        }
      }
    });
  });

  group('Safety Features Integration Tests', () {
    testWidgets('Safety settings navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to safety settings
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      final safetyButton = find.text('Safety & Privacy');
      if (safetyButton.evaluate().isNotEmpty) {
        await tester.tap(safetyButton);
        await tester.pumpAndSettle();

        // Test safety features
        expect(find.text('Safety Guidelines'), findsOneWidget);
        expect(find.text('Emergency Contacts'), findsOneWidget);
      }
    });
  });

  group('Performance Tests', () {
    testWidgets('App startup performance', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should start within 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });

    testWidgets('Navigation performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch();

      // Test navigation performance between tabs
      for (int i = 0; i < 4; i++) {
        stopwatch.start();
        
        await tester.tap(find.byType(BottomNavigationBarItem).at(i));
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Each navigation should complete within 500ms
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        stopwatch.reset();
      }
    });

    testWidgets('Memory usage test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate heavy usage by navigating multiple times
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byType(BottomNavigationBarItem).at(i % 4));
        await tester.pumpAndSettle();
      }

      // App should still be responsive
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}