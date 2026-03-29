import 'package:cloud_firestore/cloud_firestore.dart';

class AiRecommendation {
  final String id;
  final String userId;
  final String type; // 'weekly' or 'daily'
  final Timestamp generatedAt;
  final double totalCo2;
  final String recommendation;
  final Timestamp expiresAt;

  AiRecommendation({
    required this.id,
    required this.userId,
    required this.type,
    required this.generatedAt,
    required this.totalCo2,
    required this.recommendation,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'generated_at': generatedAt,
      'total_co2': totalCo2,
      'recommendation': recommendation,
      'expires_at': expiresAt,
    };
  }

  factory AiRecommendation.fromMap(String id, Map<String, dynamic> map) {
    return AiRecommendation(
      id: id,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      generatedAt: map['generated_at'] as Timestamp,
      totalCo2: (map['total_co2'] as num).toDouble(),
      recommendation: map['recommendation'] as String,
      expiresAt: map['expires_at'] as Timestamp,
    );
  }
}
