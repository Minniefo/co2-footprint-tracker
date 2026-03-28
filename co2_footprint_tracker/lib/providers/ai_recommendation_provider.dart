import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_recommendation.dart';
import '../services/ai_recommendation_service.dart';
import 'activity_provider.dart';
import 'auth_provider.dart';

final aiRecommendationServiceProvider = Provider<AiRecommendationService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final activityService = ref.watch(activityServiceProvider);
  return AiRecommendationService(firestore, activityService);
});

class AiRecommendationNotifier extends AsyncNotifier<AiRecommendation?> {
  @override
  Future<AiRecommendation?> build() async {
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) return null;

    final service = ref.read(aiRecommendationServiceProvider);
    return await service.getOrGenerateRecommendation(user.uid, 'weekly', forceRefresh: false);
  }

  Future<void> refreshRecommendation() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(aiRecommendationServiceProvider);
      return await service.getOrGenerateRecommendation(user.uid, 'weekly', forceRefresh: true);
    });
  }
}

final aiRecommendationProvider = AsyncNotifierProvider<AiRecommendationNotifier, AiRecommendation?>(AiRecommendationNotifier.new);
