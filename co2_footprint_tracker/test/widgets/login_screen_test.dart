import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:co2_footprint_tracker/screens/auth/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders correctly and validates empty fields', (WidgetTester tester) async {
    // Wrap with ProviderScope to gracefully provide AuthController
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify initial state renders properly
    expect(find.text('Welcome back to your\nCO₂ Tracker'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and Password fields

    // Attempt to login without filling fields
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    expect(loginButton, findsOneWidget);
    
    await tester.tap(loginButton);
    await tester.pumpAndSettle(); // Wait for validation animations

    // Assert that validation warnings appeared natively in the UI
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
