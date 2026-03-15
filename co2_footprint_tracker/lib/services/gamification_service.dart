import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_transaction.dart';
import '../models/badge.dart';
import '../models/user_badge.dart';

class GamificationService {
  final FirebaseFirestore _firestore;

  GamificationService(this._firestore);

  Future<void> awardPoints({
    required String userId,
    required String type,
    required int amount,
    required String reason,
    String? activityRef,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final txRef = _firestore.collection('points_transactions').doc();

    final tx = PointTransaction(
      id: txRef.id,
      userId: userId,
      type: type,
      amount: amount,
      reason: reason,
      activityRef: activityRef,
      createdAt: Timestamp.now(),
    );

    await _firestore.runTransaction((transaction) async {
      // 1. Read user doc to get current points
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return; // User must exist to award points

      final currentPoints = userDoc.data()?['points'] as int? ?? 0;

      // 2. Perform writes
      transaction.update(userRef, {
        'points': currentPoints + amount,
      });

      transaction.set(txRef, tx.toMap());
    });
  }

  Future<List<PointTransaction>> getPointHistory(String userId) async {
    final snapshot = await _firestore
        .collection('points_transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => PointTransaction.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<BadgeModel>> getAllBadges() async {
    final snapshot = await _firestore.collection('badges').get();
    return snapshot.docs
        .map((doc) => BadgeModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<UserBadge>> getUserBadges(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .orderBy('granted_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UserBadge.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateStreak(String userId, int currentStreakDays) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      int existingStreak = userDoc.data()?['streak'] as int? ?? 0;

      if (currentStreakDays > existingStreak) {
        transaction.update(userRef, {
            'streak': currentStreakDays,
        });
      }
    });
  }

  Future<void> grantBadge(String userId, String badgeId) async {
    final badgeRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .doc(badgeId);

    final userBadge = UserBadge(
      badgeId: badgeId,
      grantedAt: Timestamp.now(),
    );

    // Use set with merge true so we don't grant it multiple times if they already have it
    await badgeRef.set(userBadge.toMap(), SetOptions(merge: true));
  }
}
