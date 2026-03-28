import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final String voucherCode;
  final bool isActive;
  final Timestamp createdAt;

  Voucher({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.voucherCode,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'points_required': pointsRequired,
      'voucher_code': voucherCode,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  factory Voucher.fromMap(String id, Map<String, dynamic> map) {
    return Voucher(
      id: id,
      title: map['title'] as String? ?? 'Voucher',
      description: map['description'] as String? ?? '',
      pointsRequired: (map['points_required'] as num?)?.toInt() ?? 0,
      voucherCode: map['voucher_code'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
