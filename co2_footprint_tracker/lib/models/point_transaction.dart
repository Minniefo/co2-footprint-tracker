import 'package:cloud_firestore/cloud_firestore.dart';

class PointTransaction {
  final String? id;
  final String userId;
  final String type; // activity_saved | streak_bonus | challenge_reward
  final int amount;
  final String reason;
  final String? activityRef;
  final Timestamp createdAt;

  PointTransaction({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.reason,
    this.activityRef,
    required this.createdAt,
  });

  factory PointTransaction.fromMap(String id, Map<String, dynamic> map) {
    return PointTransaction(
      id: id,
      userId: map['user_id'] as String,
      type: map['type'] as String,
      amount: map['amount'] as int,
      reason: map['reason'] as String,
      activityRef: map['activity_ref'] as String?,
      createdAt: map['created_at'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'amount': amount,
      'reason': reason,
      'activity_ref': activityRef,
      'created_at': createdAt,
    };
  }
}
