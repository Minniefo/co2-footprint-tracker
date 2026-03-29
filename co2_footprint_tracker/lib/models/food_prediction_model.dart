class FoodPredictionModel {
  final String prediction;
  final double confidence;

  FoodPredictionModel({
    required this.prediction,
    required this.confidence,
  });

  factory FoodPredictionModel.fromJson(Map<String, dynamic> json) {
    return FoodPredictionModel(
      prediction: json['prediction'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prediction': prediction,
      'confidence': confidence,
    };
  }
}
