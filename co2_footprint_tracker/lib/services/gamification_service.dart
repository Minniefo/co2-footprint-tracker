import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point_transaction.dart';
import '../models/badge.dart';
import '../models/user_badge.dart';
import 'leaderboard_service.dart';

class GamificationService {
  final FirebaseFirestore _firestore;
  final LeaderboardService _leaderboardService;

  GamificationService(this._firestore)
      : _leaderboardService = LeaderboardService(_firestore);

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

      final currentPoints = (userDoc.data()?['points'] as num?)?.toInt() ?? 0;

      // 2. Perform writes
      transaction.set(userRef, {
        'points': currentPoints + amount,
      }, SetOptions(merge: true));

      transaction.set(txRef, tx.toMap());
    });

    // 3. Update leaderboard entry in background (non-blocking)
    //    Fetch latest user data to pass accurate totals.
    _firestore.collection('users').doc(userId).get().then((snap) {
      final data = snap.data();
      if (data == null) return;
      final newPoints = (data['points'] as num?)?.toInt() ?? 0;
      final co2 = (data['total_co2_kg'] as num?)?.toDouble() ?? 0.0;
      final name = data['display_name'] as String? ?? 'User';
      final photo = data['photo_url'] as String?;
      _leaderboardService.updateUserEntry(
        userId: userId,
        displayName: name,
        totalPoints: newPoints,
        totalCo2SavedKg: co2,
        photoUrl: photo,
      );
    }).catchError((_) {}); // Silently ignore leaderboard errors
  }

  Stream<List<PointTransaction>> streamPointHistory(String userId) {
    return _firestore
        .collection('points_transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PointTransaction.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<List<BadgeModel>> getAllBadges() async {
    final snapshot = await _firestore.collection('badges').get();
    return snapshot.docs
        .map((doc) => BadgeModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<UserBadge>> streamUserBadges(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('badges')
        .orderBy('granted_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserBadge.fromMap(doc.id, doc.data()))
            .toList());
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

  Future<void> updateStreak(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      final data = userDoc.data() ?? {};
      int currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
      int currentPoints = (data['points'] as num?)?.toInt() ?? 0;
      
      // We need the raw timestamp to do accurate timezone-agnostic calendar math
      final Timestamp? lastActiveTs = data['last_active_at'] as Timestamp?;
      
      final now = DateTime.now().toUtc();
      
      // Calculate start of today and yesterday in UTC to prevent timezone exploits
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final yesterdayUtc = todayUtc.subtract(const Duration(days: 1));

      bool streakIncremented = false;

      if (lastActiveTs == null) {
        // First ever activity
        currentStreak = 1;
        streakIncremented = true;
      } else {
        final lastActiveDate = lastActiveTs.toDate().toUtc();
        final lastActiveDayUtc = DateTime.utc(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);

        if (lastActiveDayUtc.isAtSameMomentAs(todayUtc)) {
          // Already logged an activity today. Streak remains the same.
        } else if (lastActiveDayUtc.isAtSameMomentAs(yesterdayUtc)) {
          // Logged activity yesterday. Valid streak continuation!
          currentStreak += 1;
          streakIncremented = true;
        } else if (lastActiveDayUtc.isBefore(yesterdayUtc)) {
          // Streak broken (missed yesterday or more)
          currentStreak = 1;
          streakIncremented = true;
        } else {
          // Future date (device clock manipulation?)
          // We'll reset it to 1 just to be safe
          currentStreak = 1;
          streakIncremented = true;
        }
      }

      // Prepare updates
      final updates = <String, dynamic>{
        'last_active_at': FieldValue.serverTimestamp(),
        'streak': currentStreak,
      };

      // If they earned a streak continuation, give them bonus points (e.g., +5)
      if (streakIncremented && currentStreak > 1) {
        final bonusAmount = 5;
        updates['points'] = currentPoints + bonusAmount;

        final txRef = _firestore.collection('points_transactions').doc();
        final tx = PointTransaction(
          id: txRef.id,
          userId: userId,
          type: 'streak_bonus',
          amount: bonusAmount,
          reason: '$currentStreak Day Streak Bonus!',
          createdAt: Timestamp.now(),
        );
        transaction.set(txRef, tx.toMap());
      }

      transaction.set(userRef, updates, SetOptions(merge: true));
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
