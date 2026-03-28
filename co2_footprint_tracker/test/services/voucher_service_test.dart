import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:co2_footprint_tracker/services/voucher_service.dart';
import 'package:co2_footprint_tracker/models/voucher_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('VoucherService Transactions (Using Fake Firestore)', () {
    late FakeFirebaseFirestore fakeFirestore;
    late VoucherService voucherService;

    setUp(() {
      // 1. Initialize a pure local RAM clone of Firestore
      fakeFirestore = FakeFirebaseFirestore();
      voucherService = VoucherService(fakeFirestore);
    });

    test('redeemVoucher successfully deducts points and issues voucher atomically', () async {
      // Setup fake user with 500 points
      await fakeFirestore.collection('users').doc('user123').set({
        'points': 500,
      });

      // Define a fake voucher
      final voucher = Voucher(
        id: 'v1',
        title: 'Discount',
        description: 'Test Description',
        pointsRequired: 200,
        voucherCode: 'CODE123',
        isActive: true,
        createdAt: Timestamp.now(),
      );

      // Execute redemption
      await voucherService.redeemVoucher('user123', voucher);

      // Verify points were deducted
      final userDoc = await fakeFirestore.collection('users').doc('user123').get();
      expect(userDoc.data()?['points'], 300);

      // Verify the voucher was written into user subcollection securely
      final voucherDoc = await fakeFirestore.collection('users').doc('user123').collection('vouchers').doc('v1').get();
      expect(voucherDoc.exists, true);
      expect(voucherDoc.data()?['voucher_code'], 'CODE123');
    });

    test('redeemVoucher terminates and throws error if insufficient points', () async {
      // Setup fake user with only 100 points
      await fakeFirestore.collection('users').doc('user123').set({
        'points': 100, 
      });

      final voucher = Voucher(
        id: 'v1',
        title: 'Discount',
        description: 'Test',
        pointsRequired: 200,
        voucherCode: 'CODE123',
        isActive: true,
        createdAt: Timestamp.now(),
      );

      // Execution expects a hard transaction throw
      expect(
        () => voucherService.redeemVoucher('user123', voucher),
        throwsA(isA<Exception>()),
      );
    });
  });
}
