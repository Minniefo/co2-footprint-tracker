import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import 'auth_provider.dart';
import 'leaderboard_provider.dart';

// ── Public profile (real-time stream to react to privacy changes) ───────────
final publicProfileProvider = StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(firestoreProvider).collection('users').doc(uid).snapshots().map((snap) {
    if (!snap.exists || snap.data() == null) return null;
    return UserModel.fromMap(snap.data()!);
  });
});

// ── Current week leaderboard entry for the viewed user ──────────────────────
final publicProfileRankProvider = StreamProvider.family<LeaderboardEntry?, String>((ref, uid) {
  return ref.watch(weeklyLeaderboardProvider).when(
        data: (entries) => Stream.value(entries.where((e) => e.userId == uid).firstOrNull),
        loading: () => const Stream.empty(),
        error: (_, __) => Stream.value(null),
      );
});
