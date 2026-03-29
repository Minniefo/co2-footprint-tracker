import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:co2_footprint_tracker/screens/auth/signup_screen.dart';

void main() {
  testWidgets('SignupScreen renders correctly and validates empty form submissions', (WidgetTester tester) async {
    // 1. Pump the Signup UI natively
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SignupScreen(),
        ),
      ),
    );

    // 2. Verify title exists
    expect(find.text('Create Account'), findsWidgets);

    // 3. Find the submit button. There is a "Create Account" text in the header and in the button.
    final submitButton = find.widgetWithText(ElevatedButton, 'Create Account');
    expect(submitButton, findsOneWidget);

    // 4. Since the form is very long, ensure the button is scrolled into view before clicking
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    
    // 5. Wait for the form validation red text to appear
    await tester.pumpAndSettle();

    // 6. Assert all the field validation triggers activated
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Display Name is required'), findsOneWidget);
    expect(find.text('Country is required'), findsOneWidget);
    expect(find.text('Home Type is required'), findsOneWidget);
    expect(find.text('Diet Type is required'), findsOneWidget);
  });
}
