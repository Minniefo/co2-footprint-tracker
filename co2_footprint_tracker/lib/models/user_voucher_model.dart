import 'package:cloud_firestore/cloud_firestore.dart';

class UserVoucher {
  final String id;
  final String voucherId;
  final String title;
  final String voucherCode;
  final Timestamp redeemedAt;

  UserVoucher({
    required this.id,
    required this.voucherId,
    required this.title,
    required this.voucherCode,
    required this.redeemedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'voucher_id': voucherId,
      'title': title,
      'voucher_code': voucherCode,
      'redeemed_at': redeemedAt,
    };
  }

  factory UserVoucher.fromMap(String id, Map<String, dynamic> map) {
    return UserVoucher(
      id: id,
      voucherId: map['voucher_id'] as String? ?? '',
      title: map['title'] as String? ?? 'Voucher',
      voucherCode: map['voucher_code'] as String? ?? '',
      redeemedAt: map['redeemed_at'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
