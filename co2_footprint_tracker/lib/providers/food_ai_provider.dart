import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_prediction_model.dart';
import '../models/nutrition_model.dart';
import '../services/food_ai_service.dart';
import '../services/nutrition_service.dart';

final foodAIServiceProvider = Provider((ref) => FoodAIService());
final nutritionServiceProvider = Provider((ref) => NutritionService());

class FoodAIState {
  final bool isLoading;
  final String? error;
  final FoodPredictionModel? prediction;
  final NutritionModel? nutrition;
  final File? image;

  FoodAIState({
    this.isLoading = false,
    this.error,
    this.prediction,
    this.nutrition,
    this.image,
  });

  FoodAIState copyWith({
    bool? isLoading,
    String? error,
    FoodPredictionModel? prediction,
    NutritionModel? nutrition,
    File? image,
    bool clearError = false,
  }) {
    return FoodAIState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      prediction: prediction ?? this.prediction,
      nutrition: nutrition ?? this.nutrition,
      image: image ?? this.image,
    );
  }
}

class FoodAINotifier extends Notifier<FoodAIState> {
  @override
  FoodAIState build() {
    return FoodAIState();
  }

  void reset() {
    state = FoodAIState();
  }

  Future<void> analyzeFood(File imageFile) async {
    state = state.copyWith(isLoading: true, image: imageFile, clearError: true);

    try {
      final foodAIService = ref.read(foodAIServiceProvider);
      final nutritionService = ref.read(nutritionServiceProvider);

      // 1. Predict food
      final prediction = await foodAIService.predictFood(imageFile);
      state = state.copyWith(prediction: prediction);

      // 2. Fetch nutrition & CO2
      final nutrition = await nutritionService.getNutritionAndCo2(prediction.prediction);
      
      state = state.copyWith(
        isLoading: false,
        nutrition: nutrition,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final foodAIProvider = NotifierProvider<FoodAINotifier, FoodAIState>(FoodAINotifier.new);
