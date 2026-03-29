import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:co2_footprint_tracker/screens/rewards/my_vouchers_screen.dart';
import 'package:co2_footprint_tracker/providers/voucher_provider.dart';

void main() {
  testWidgets('MyVouchersScreen displays empty state when user has 0 vouchers', (WidgetTester tester) async {
    // We pump the widget inside a ProviderScope so we can easily mock Riverpod states
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the network request to return an empty array instantly
          myVouchersProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: MyVouchersScreen(),
        ),
      ),
    );

    // Let the animations and futures settle
    await tester.pumpAndSettle();

    // Verify the UI renders the correct empty state text
    expect(find.text('No vouchers yet!'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });
}
