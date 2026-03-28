import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher_model.dart';
import '../models/user_voucher_model.dart';

class VoucherService {
  final FirebaseFirestore _firestore;

  VoucherService(this._firestore);

  // 1. Fetch available active vouchers
  Future<List<Voucher>> getActiveVouchers() async {
    final query = await _firestore
        .collection('vouchers')
        .where('is_active', isEqualTo: true)
        .orderBy('points_required')
        .get();

    return query.docs.map((doc) => Voucher.fromMap(doc.id, doc.data())).toList();
  }

  // 2. Fetch User's redeemed vouchers (Stream)
  Stream<List<UserVoucher>> getUserVouchers(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vouchers')
        .orderBy('redeemed_at', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserVoucher.fromMap(doc.id, doc.data())).toList());
  }

  // 3. Redeem Voucher (ATOMIC TRANSACTION)
  Future<void> redeemVoucher(String uid, Voucher voucher) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userVouchersRef = userRef.collection('vouchers');

    await _firestore.runTransaction((transaction) async {
      // Read User Document
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw Exception("User not found.");
      }

      final points = (userSnapshot.data()?['points'] as num?)?.toInt() ?? 0;

      // Check sufficient points
      if (points < voucher.pointsRequired) {
        throw Exception("Insufficient points to redeem this voucher.");
      }

      // Verify they haven't already redeemed this voucher
      // For one-off redemptions, we use voucher.id as the document ID
      final userVoucherDocRef = userVouchersRef.doc(voucher.id);
      final userVoucherSnapshot = await transaction.get(userVoucherDocRef);

      if (userVoucherSnapshot.exists) {
         throw Exception("You have already redeemed this voucher.");
      }

      // Update user points
      final newPoints = points - voucher.pointsRequired;
      transaction.update(userRef, {'points': newPoints});

      // Save the voucher
      final newUserVoucher = UserVoucher(
        id: voucher.id,
        voucherId: voucher.id,
        title: voucher.title,
        voucherCode: voucher.voucherCode,
        redeemedAt: Timestamp.now(),
      );
      
      transaction.set(userVoucherDocRef, newUserVoucher.toMap());
    });
  }

  // Helper to quickly seed dummy vouchers if the database is empty
  Future<void> seedDummyVouchersIfEmpty() async {
    final snapshot = await _firestore.collection('vouchers').limit(1).get();
    if (snapshot.docs.isEmpty) {
      final batch = _firestore.batch();
      final collection = _firestore.collection('vouchers');

      final dummyVouchers = [
        Voucher(
          id: collection.doc().id,
          title: "10% Off Eco Store",
          description: "Use this code to get a 10% discount on all sustainable products at the eco store online.",
          pointsRequired: 200,
          voucherCode: "ECO10OFF",
          isActive: true,
          createdAt: Timestamp.now(),
        ),
        Voucher(
          id: collection.doc().id,
          title: "Free Reusable Cup",
          description: "Redeem this for a beautiful sleek reusable coffee cup at participating cafes.",
          pointsRequired: 500,
          voucherCode: "FREECUP500",
          isActive: true,
          createdAt: Timestamp.now(),
        ),
         Voucher(
          id: collection.doc().id,
          title: "Plant a Tree",
          description: "We will plant a certified tree on your behalf when you redeem this voucher to offset more carbon! 🌲",
          pointsRequired: 1000,
          voucherCode: "TREETRACKER",
          isActive: true,
          createdAt: Timestamp.now(),
        ),
      ];

      for (var v in dummyVouchers) {
        batch.set(collection.doc(v.id), v.toMap());
      }
      await batch.commit();
    }
  }
}
