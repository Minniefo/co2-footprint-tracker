import 'package:cloud_firestore/cloud_firestore.dart';

class UserBadge {
  final String badgeId;
  final Timestamp grantedAt;

  UserBadge({
    required this.badgeId,
    required this.grantedAt,
  });

  factory UserBadge.fromMap(String id, Map<String, dynamic> map) {
    return UserBadge(
      badgeId: id,
      grantedAt: map['granted_at'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'granted_at': grantedAt,
    };
  }
}
