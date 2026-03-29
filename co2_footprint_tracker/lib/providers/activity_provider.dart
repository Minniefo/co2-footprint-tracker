import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity.dart';
import '../services/activity_service.dart';
import 'auth_provider.dart';
import 'emission_factors_provider.dart';
import 'gamification_provider.dart';

import '../services/co2_calculator.dart';

final activityServiceProvider = Provider<ActivityService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ActivityService(firestore);
});

final co2CalculatorProvider = FutureProvider<Co2Calculator>((ref) async {
  final factors = await ref.watch(emissionFactorsProvider.future);
  return Co2Calculator(factors);
});

final userActivitiesProvider = StreamProvider<List<Activity>>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value([]);
  
  final service = ref.watch(activityServiceProvider);
  return service.streamUserActivities(user.uid);
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

      // 1. Get calculator
      final calculator = await ref.read(co2CalculatorProvider.future);
      
      // 2. Calculate CO2
      final co2Kg = calculator.calculateTransport(transportMode, distanceKm ?? 1.0);

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

      // Update Streak
      await ref.read(gamificationServiceProvider).updateStreak(user.uid);

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
    double? explicitCo2Kg,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Get calculator
      final calculator = await ref.read(co2CalculatorProvider.future);
      
      // 2. Calculate CO2
      final co2Kg = explicitCo2Kg != null 
          ? (explicitCo2Kg * servings) 
          : calculator.calculateFood(foodCategory, servings);

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

      // Update Streak
      await ref.read(gamificationServiceProvider).updateStreak(user.uid);

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

      // 1. Get calculator
      final calculator = await ref.read(co2CalculatorProvider.future);
      
      // 2. Calculate CO2
      final co2Kg = calculator.calculateEnergy(energyType, kwh);

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

      // Update Streak
      await ref.read(gamificationServiceProvider).updateStreak(user.uid);

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
