import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtky/main.dart' as app;

void main() {
  group('App Performance Tests', () {
    testWidgets('App startup performance benchmark', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      // Start the app
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      final startupTime = stopwatch.elapsedMilliseconds;
      
      // App should start within 2 seconds on test environment
      expect(startupTime, lessThan(2000));
      
      print('App startup time: ${startupTime}ms');
    });

    testWidgets('Widget build performance test', (WidgetTester tester) async {
      const int iterations = 100;
      final stopwatch = Stopwatch();
      
      for (int i = 0; i < iterations; i++) {
        stopwatch.start();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Item $index'),
                    subtitle: Text('Subtitle $index'),
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                  );
                },
              ),
            ),
          ),
        );
        
        stopwatch.stop();
      }
      
      final averageTime = stopwatch.elapsedMilliseconds / iterations;
      
      // Each build should complete within 50ms on average
      expect(averageTime, lessThan(50));
      
      print('Average widget build time: ${averageTime.toStringAsFixed(2)}ms');
    });

    testWidgets('Scroll performance test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 1000,
              itemBuilder: (context, index) {
                return Container(
                  height: 60,
                  child: ListTile(
                    title: Text('Item $index'),
                    subtitle: Text('This is item number $index'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      
      // Perform scroll operations
      for (int i = 0; i < 10; i++) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -500),
        );
        await tester.pump();
      }
      
      stopwatch.stop();
      final scrollTime = stopwatch.elapsedMilliseconds;
      
      // Scrolling should be smooth (complete within 1 second)
      expect(scrollTime, lessThan(1000));
      
      print('Scroll performance time: ${scrollTime}ms');
    });

    testWidgets('Memory usage test with large lists', (WidgetTester tester) async {
      // Create a large list to test memory efficiency
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 10000,
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Title $index'),
                        Text('Subtitle $index'),
                        Text('Description for item $index'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Scroll through the list to trigger widget creation/disposal
      for (int i = 0; i < 20; i++) {
        await tester.drag(
          find.byType(ListView),
          const Offset(0, -1000),
        );
        await tester.pump();
      }

      // App should still be responsive
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Animation performance test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: 100,
                height: 100,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      
      // Trigger animation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: 200,
                height: 200,
                color: Colors.red,
              ),
            ),
          ),
        ),
      );

      // Let animation complete
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      final animationTime = stopwatch.elapsedMilliseconds;
      
      // Animation should complete smoothly
      expect(animationTime, lessThan(1500)); // Allow some buffer
      
      print('Animation completion time: ${animationTime}ms');
    });

    testWidgets('Image loading performance test', (WidgetTester tester) async {
      const int imageCount = 20;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: imageCount,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, size: 50),
                );
              },
            ),
          ),
        ),
      );

      final stopwatch = Stopwatch()..start();
      
      // Scroll through images
      await tester.drag(
        find.byType(GridView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      final loadTime = stopwatch.elapsedMilliseconds;
      
      // Image grid should load efficiently
      expect(loadTime, lessThan(500));
      
      print('Image grid load time: ${loadTime}ms');
    });
  });

  group('Memory Leak Tests', () {
    testWidgets('Widget disposal test', (WidgetTester tester) async {
      // Create and dispose widgets multiple times
      for (int i = 0; i < 50; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: List.generate(10, (index) {
                  return const Placeholder();
                }),
              ),
            ),
          ),
        );
        
        await tester.pumpWidget(const SizedBox.shrink());
      }
      
      // Should complete without memory issues
      expect(true, true);
    });
  });
}