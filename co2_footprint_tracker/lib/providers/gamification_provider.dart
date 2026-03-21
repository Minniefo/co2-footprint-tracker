import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/point_transaction.dart';
import '../models/badge.dart';
import '../models/user_badge.dart';
import '../models/activity.dart';
import '../services/gamification_service.dart';
import 'auth_provider.dart';
import 'activity_provider.dart';

final gamificationServiceProvider = Provider<GamificationService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return GamificationService(firestore);
});

final pointHistoryProvider = StreamProvider<List<PointTransaction>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  
  final service = ref.watch(gamificationServiceProvider);
  return service.streamPointHistory(user.uid);
});

final allBadgesProvider = FutureProvider<List<BadgeModel>>((ref) async {
  final service = ref.watch(gamificationServiceProvider);
  return service.getAllBadges();
});

final userBadgesProvider = StreamProvider<List<UserBadge>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  
  final service = ref.watch(gamificationServiceProvider);
  return service.streamUserBadges(user.uid);
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

      // 2. Check for newly earned badges
      final allBadges = await ref.read(allBadgesProvider.future);
      final currentBadges = await service.getUserBadges(user.uid);
      final grantedIds = currentBadges.map((b) => b.badgeId).toSet();

      // We need updated user stats to check criteria
      final userDoc = await ref.read(firestoreProvider).collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final totalPoints = userData['points'] is num ? (userData['points'] as num).toInt() : (int.tryParse(userData['points']?.toString() ?? '0') ?? 0);
      final currentStreak = userData['streak'] is num ? (userData['streak'] as num).toInt() : (int.tryParse(userData['streak']?.toString() ?? '0') ?? 0);
      
      // Determine activity counts for criteria
      final allActivities = await ref.read(activityServiceProvider).getUserActivities(user.uid);
      final totalActivities = allActivities.length;
      final transportActivities = allActivities.where((a) => a.activityType == 'transport').length;
      final veganMeals = allActivities.where((a) => a.activityType == 'food' && (a as FoodActivity).foodCategory == 'vegan_meal').length;

      for (final badge in allBadges) {
        if (grantedIds.contains(badge.badgeId)) continue; // Already have it

        bool criteriaMet = true;
        final criteria = badge.criteria;

        if (criteria.containsKey('activities_count')) {
          final req = num.tryParse(criteria['activities_count'].toString()) ?? 0;
          if (totalActivities < req) criteriaMet = false;
        }
        if (criteria.containsKey('streak_days')) {
          final req = num.tryParse(criteria['streak_days'].toString()) ?? 0;
          if (currentStreak < req) criteriaMet = false;
        }
        if (criteria.containsKey('transport_activities_count')) {
          final req = num.tryParse(criteria['transport_activities_count'].toString()) ?? 0;
          if (transportActivities < req) criteriaMet = false;
        }
        if (criteria.containsKey('vegan_meals_count')) {
          final req = num.tryParse(criteria['vegan_meals_count'].toString()) ?? 0;
          if (veganMeals < req) criteriaMet = false;
        }
        if (criteria.containsKey('total_points')) {
          // Add the newly awarded amount to the current snapshot total just in case
          final req = num.tryParse(criteria['total_points'].toString()) ?? 0;
          if ((totalPoints + amount) < req) criteriaMet = false;
        }

        if (criteriaMet && criteria.isNotEmpty) {
          // Grant the badge
          await service.grantBadge(user.uid, badge.badgeId);
          // Also award some bonus points for getting a badge!
          await service.awardPoints(
            userId: user.uid, 
            type: 'challenge_reward', 
            amount: 20, 
            reason: 'Earned Badge: ${badge.title}',
          );
        }
      }

      // 3. (Data refreshes dynamically via streams, so no explicit ref.invalidate needed)
      
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

      // Stream auto-updates userBadgesProvider
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final gamificationControllerProvider = AsyncNotifierProvider<GamificationController, void>(GamificationController.new);
