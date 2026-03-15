import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';
import '../services/activity_service.dart';
import 'auth_provider.dart';
import 'emission_factors_provider.dart';
import 'gamification_provider.dart';

final activityServiceProvider = Provider<ActivityService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ActivityService(firestore);
});

final userActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return [];
  
  final service = ref.watch(activityServiceProvider);
  return service.getUserActivities(user.uid);
});

class ActivityController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> logTransportActivity({
    required String transportMode,
    String? startArea,
    String? endArea,
    double? distanceKm,
    String? mapboxRouteId,
    Map<String, dynamic>? privacy,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Get emission factors
      final factors = await ref.read(emissionFactorsProvider.future);
      
      // 2. Calculate CO2
      final factor = factors.getTransportFactor(transportMode);
      final dist = distanceKm ?? 1.0; 
      final co2Kg = factor * dist;

      // 3. Create Activity
      final docId = ref.read(firestoreProvider).collection('activities').doc().id;
      final activity = TransportActivity(
        id: docId,
        userId: user.uid,
        transportMode: transportMode,
        startArea: startArea,
        endArea: endArea,
        distanceKm: distanceKm,
        co2Kg: co2Kg,
        mapboxRouteId: mapboxRouteId,
        privacy: privacy,
        createdAt: Timestamp.now(),
      );

      // 4. Save
      await ref.read(activityServiceProvider).saveActivity(activity);
      
      // Refresh activities
      ref.invalidate(userActivitiesProvider);

      // Award Points
      await ref.read(gamificationControllerProvider.notifier).awardPointsAndCheckBadges(
        type: 'activity_saved',
        amount: 10,
        reason: 'Logged transport activity',
        activityRef: docId,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      throw Exception('Failed to log transport: $e');
    }
  }

  Future<void> logFoodActivity({
    required String foodCategory,
    int servings = 1,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      // Static calculation for food as example, could be brought from settings too
      final fallbackFactors = {
        'meat_meal': 3.2,
        'vegetarian_meal': 1.1,
        'vegan_meal': 0.7,
      };
      
      final co2Kg = (fallbackFactors[foodCategory] ?? 1.0) * servings;

      final docId = ref.read(firestoreProvider).collection('activities').doc().id;
      final activity = FoodActivity(
        id: docId,
        userId: user.uid,
        foodCategory: foodCategory,
        servings: servings,
        co2Kg: co2Kg,
        createdAt: Timestamp.now(),
      );

      await ref.read(activityServiceProvider).saveActivity(activity);
      ref.invalidate(userActivitiesProvider);

      // Award Points
      await ref.read(gamificationControllerProvider.notifier).awardPointsAndCheckBadges(
        type: 'activity_saved',
        amount: 10,
        reason: 'Logged food activity',
        activityRef: docId,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      throw Exception('Failed to log food: $e');
    }
  }

  Future<void> logEnergyActivity({
    required String energyType,
    required double kwh,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      // Static calculation for energy
      final fallbackFactors = {
        'electricity': 0.5,
        'gas': 0.2,
      };
      
      final co2Kg = (fallbackFactors[energyType] ?? 0.5) * kwh;

      final docId = ref.read(firestoreProvider).collection('activities').doc().id;
      final activity = EnergyActivity(
        id: docId,
        userId: user.uid,
        energyType: energyType,
        kwh: kwh,
        co2Kg: co2Kg,
        createdAt: Timestamp.now(),
      );

      await ref.read(activityServiceProvider).saveActivity(activity);
      ref.invalidate(userActivitiesProvider);

      // Award Points
      await ref.read(gamificationControllerProvider.notifier).awardPointsAndCheckBadges(
        type: 'activity_saved',
        amount: 10,
        reason: 'Logged energy activity',
        activityRef: docId,
      );

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      throw Exception('Failed to log energy: $e');
    }
  }
}

final activityControllerProvider = AsyncNotifierProvider<ActivityController, void>(ActivityController.new);
