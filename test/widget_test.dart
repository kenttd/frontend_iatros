import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:forui/forui.dart';
import 'package:iatros/src/common_widgets/bottom_navbar.dart';

void main() {
  testWidgets('BottomNavbar smoke test', (WidgetTester tester) async {
    // We need to verify that tapping the item navigates.
    // We can do this by showing a specific widget for the destination route.

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Text('Home Screen'),
            bottomNavigationBar: BottomNavbar(),
          ),
        ),
        GoRoute(
          path: '/messaging',
          builder: (context, state) => const Scaffold(
            body: Text('Messaging Screen'),
            bottomNavigationBar: BottomNavbar(),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const Scaffold(
            body: Text('Search Screen'),
            bottomNavigationBar: BottomNavbar(),
          ),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const Scaffold(
            body: Text('Map Screen'),
            bottomNavigationBar: BottomNavbar(),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(
            body: Text('Settings Screen'),
            bottomNavigationBar: BottomNavbar(),
          ),
        ),
      ],
    );

    // Wrap in FTheme because BottomNavbar uses ForUI widgets
    await tester.pumpWidget(
      FTheme(
        data: FThemes.zinc.light,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Verify we are at Home
    expect(find.text('Home Screen'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget); // Navbar label
    expect(find.text('Messages'), findsOneWidget); // Navbar label

    // Tap on Messages
    await tester.tap(find.text('Messages'));
    // Allow animation/navigation to settle
    await tester.pumpAndSettle();

    // Verify we are at Messaging
    expect(find.text('Messaging Screen'), findsOneWidget);
    // Verify Home Screen text is gone
    expect(find.text('Home Screen'), findsNothing);
  });
}
