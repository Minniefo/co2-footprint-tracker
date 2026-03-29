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

class AiRecommendationTabNotifier extends Notifier<String> {
  @override
  String build() => 'weekly';

  void setTab(String tab) {
    state = tab;
  }
}

final aiRecommendationTabProvider = NotifierProvider<AiRecommendationTabNotifier, String>(AiRecommendationTabNotifier.new);

class AiRecommendationNotifier extends AsyncNotifier<AiRecommendation?> {
  @override
  Future<AiRecommendation?> build() async {
    final user = ref.watch(authStateChangesProvider).value;
    final type = ref.watch(aiRecommendationTabProvider);
    if (user == null) return null;

    final service = ref.read(aiRecommendationServiceProvider);
    return await service.getOrGenerateRecommendation(user.uid, type, forceRefresh: false);
  }

  Future<void> refreshRecommendation() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    final type = ref.read(aiRecommendationTabProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(aiRecommendationServiceProvider);
      return await service.getOrGenerateRecommendation(user.uid, type, forceRefresh: true);
    });
  }
}

final aiRecommendationProvider = AsyncNotifierProvider<AiRecommendationNotifier, AiRecommendation?>(AiRecommendationNotifier.new);
