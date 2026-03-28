class NutritionModel {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final String source;
  final double co2EstimateKg;
  final String matchedCategory;

  NutritionModel({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.source,
    required this.co2EstimateKg,
    required this.matchedCategory,
  });

  factory NutritionModel.fromJson(Map<String, dynamic> json) {
    return NutritionModel(
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'AI Estimated',
      co2EstimateKg: (json['co2_kg'] as num?)?.toDouble() ?? 0.0,
      matchedCategory: json['category'] as String? ?? 'vegetarian',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'source': source,
      'co2_kg': co2EstimateKg,
      'category': matchedCategory,
    };
  }
}
