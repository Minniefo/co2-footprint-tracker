import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore;

  LeaderboardService(this._firestore);

  /// Returns the Firestore week ID for the current week, e.g. "2026_W12"
  static String currentWeekId() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final weekNumber = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}_W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Streams the top entries for the current week, ordered by rank.
  Stream<List<LeaderboardEntry>> watchWeeklyLeaderboard({int limit = 50}) {
    final weekId = currentWeekId();
    return _firestore
        .collection('leaderboard_weekly')
        .doc(weekId)
        .collection('entries')
        .orderBy('rank')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// One-time fetch of a specific user's entry (to show rank outside top 50).
  Future<LeaderboardEntry?> getUserEntry(String userId) async {
    final weekId = currentWeekId();
    final doc = await _firestore
        .collection('leaderboard_weekly')
        .doc(weekId)
        .collection('entries')
        .doc(userId)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return LeaderboardEntry.fromMap(doc.id, doc.data()!);
  }

  /// Writes (or updates) the current user's leaderboard entry for this week.
  /// Called every time the user earns points or saves CO₂.
  /// Rank is set to 0 initially; the re-ranking query below runs after each update.
  Future<void> updateUserEntry({
    required String userId,
    required String displayName,
    required int totalPoints,
    required double totalCo2SavedKg,
    String? photoUrl,
  }) async {
    final weekId = currentWeekId();
    final entryRef = _firestore
        .collection('leaderboard_weekly')
        .doc(weekId)
        .collection('entries')
        .doc(userId);

    await entryRef.set({
      'user_id': userId,
      'display_name': displayName,
      'points': totalPoints,
      'co2_saved_kg': totalCo2SavedKg,
      if (photoUrl != null) 'photo_url': photoUrl,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // After saving the entry, recompute ranks for this week
    await _recomputeRanks(weekId);
  }

  /// Reads all entries ordered by points, then writes back the rank field.
  /// This is efficient for small leaderboards (<= a few hundred users).
  Future<void> _recomputeRanks(String weekId) async {
    final snap = await _firestore
        .collection('leaderboard_weekly')
        .doc(weekId)
        .collection('entries')
        .orderBy('points', descending: true)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var i = 0; i < snap.docs.length; i++) {
      batch.update(snap.docs[i].reference, {'rank': i + 1});
    }
    await batch.commit();
  }
}

