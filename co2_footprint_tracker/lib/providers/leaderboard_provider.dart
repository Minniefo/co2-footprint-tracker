import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import 'auth_provider.dart';

final leaderboardServiceProvider = Provider<LeaderboardService>((ref) {
  return LeaderboardService(ref.watch(firestoreProvider));
});

/// Streams the top-50 entries for the current week.
final weeklyLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(leaderboardServiceProvider).watchWeeklyLeaderboard();
});

/// The current ISO week label, e.g. "Week 12 · 2026"
final currentWeekLabelProvider = Provider<String>((ref) {
  final id = LeaderboardService.currentWeekId(); // "2026_W12"
  final parts = id.split('_W');
  final year = parts[0];
  final week = int.tryParse(parts[1]) ?? 0;
  return 'Week $week · $year';
});

/// Convenience — finds the current user's entry inside the streamed list.
/// Returns null if the user is not in the list (outside top 50).
final currentUserEntryProvider = Provider<LeaderboardEntry?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final entries = ref.watch(weeklyLeaderboardProvider).value ?? [];
  try {
    return entries.firstWhere((e) => e.userId == uid);
  } catch (_) {
    return null;
  }
});
