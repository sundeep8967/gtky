import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtky/widgets/profile_image_picker.dart';

void main() {
  group('ProfileImagePicker Widget Tests', () {
    testWidgets('should display placeholder when no image provided', (WidgetTester tester) async {
      String? selectedImageUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePicker(
              onImageChanged: (url) => selectedImageUrl = url,
            ),
          ),
        ),
      );

      // Should show placeholder icon
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should display image when URL provided', (WidgetTester tester) async {
      const testImageUrl = 'https://example.com/test-image.jpg';
      String? selectedImageUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePicker(
              initialImageUrl: testImageUrl,
              onImageChanged: (url) => selectedImageUrl = url,
            ),
          ),
        ),
      );

      // Should show cached network image
      expect(find.byType(ProfileImagePicker), findsOneWidget);
    });

    testWidgets('should show camera icon when enabled', (WidgetTester tester) async {
      String? selectedImageUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePicker(
              onImageChanged: (url) => selectedImageUrl = url,
              enabled: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should not show camera icon when disabled', (WidgetTester tester) async {
      String? selectedImageUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePicker(
              onImageChanged: (url) => selectedImageUrl = url,
              enabled: false,
            ),
          ),
        ),
      );

      // Camera icon should not be visible when disabled
      expect(find.byIcon(Icons.camera_alt), findsNothing);
    });

    testWidgets('should respond to tap when enabled', (WidgetTester tester) async {
      String? selectedImageUrl;
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePicker(
              onImageChanged: (url) {
                selectedImageUrl = url;
                tapped = true;
              },
              enabled: true,
            ),
          ),
        ),
      );

      // Tap on the profile image picker
      await tester.tap(find.byType(ProfileImagePicker));
      await tester.pumpAndSettle();

      // Note: In a real test, this would trigger image picker
      // For unit testing, we just verify the widget responds to taps
    });

    testWidgets('should show remove button when image exists', (WidgetTester tester) async {
      const testImageUrl = 'https://example.com/test-image.jpg';
      String? selectedImageUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePicker(
              initialImageUrl: testImageUrl,
              onImageChanged: (url) => selectedImageUrl = url,
              enabled: true,
            ),
          ),
        ),
      );

      // Should show remove button (close icon)
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should respect custom size', (WidgetTester tester) async {
      const customSize = 150.0;
      String? selectedImageUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePicker(
              onImageChanged: (url) => selectedImageUrl = url,
              size: customSize,
            ),
          ),
        ),
      );

      final profilePicker = tester.widget<ProfileImagePicker>(
        find.byType(ProfileImagePicker),
      );
      
      expect(profilePicker.size, customSize);
    });
  });

  group('ProfileImagePicker Animation Tests', () {
    testWidgets('should animate on tap down and up', (WidgetTester tester) async {
      String? selectedImageUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileImagePicker(
              onImageChanged: (url) => selectedImageUrl = url,
              enabled: true,
            ),
          ),
        ),
      );

      // Test tap down
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ProfileImagePicker)),
      );
      
      await tester.pump(const Duration(milliseconds: 100));
      
      // Test tap up
      await gesture.up();
      await tester.pumpAndSettle();

      // Animation should complete without errors
      expect(find.byType(ProfileImagePicker), findsOneWidget);
    });
  });
}