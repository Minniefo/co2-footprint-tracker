import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/point_transaction.dart';
import '../models/badge.dart';
import '../models/user_badge.dart';
import '../services/gamification_service.dart';
import 'auth_provider.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return GamificationService(firestore);
});

final pointHistoryProvider = FutureProvider<List<PointTransaction>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  
  final service = ref.watch(gamificationServiceProvider);
  return service.getPointHistory(user.uid);
});

final allBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getAllBadges();
});

final userBadgesProvider = FutureProvider<List<UserBadge>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  
  final service = ref.watch(gamificationServiceProvider);
  return service.getUserBadges(user.uid);
});

class GamificationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> awardPointsAndCheckBadges({
    required String type,
    required int amount,
    required String reason,
    String? activityRef,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      final service = ref.read(gamificationServiceProvider);
      
      // 1. Award points
      await service.awardPoints(
        userId: user.uid,
        type: type,
        amount: amount,
        reason: reason,
        activityRef: activityRef,
      );

      // 2. We can later add badge logic here (e.g., checking if user crossed a milestone)
      // For now, let's keep it simple.

      // 3. Refresh data
      ref.invalidate(pointHistoryProvider);
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> grantBadge(String badgeId) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      final service = ref.read(gamificationServiceProvider);
      await service.grantBadge(user.uid, badgeId);

      ref.invalidate(userBadgesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final gamificationControllerProvider = AsyncNotifierProvider<GamificationController, void>(GamificationController.new);
