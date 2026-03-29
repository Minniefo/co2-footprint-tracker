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

    // 3. Find the "Next: Eco Profile" button used in step 1.
    final nextButton = find.widgetWithText(ElevatedButton, 'Next: Eco Profile');
    expect(nextButton, findsOneWidget);

    // 4. Since the form is very long, ensure the button is scrolled into view before clicking
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    
    // 5. Wait for the form validation red text to appear
    await tester.pumpAndSettle();

    // 6. Assert all the required field validation triggers activated in Step 1
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
    expect(find.text('Display name is required'), findsOneWidget);
  });
}
