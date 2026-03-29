import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? displayName;
  final String email;
  final String? photoUrl;
  final String? country;
  final String? homeType;
  final String? dietType;
  final int? householdSize;
  final String? preferredTransport;
  final Timestamp? createdAt;
  final Timestamp? lastActiveAt;
  final double? totalCo2Kg;
  final int? points;
  final int? streak;
  final bool needsOnboarding;
  final PrivacySettings? privacy;

  UserModel({
    this.displayName,
    required this.email,
    this.photoUrl,
    this.country,
    this.homeType,
    this.dietType,
    this.householdSize,
    this.preferredTransport,
    this.createdAt,
    this.lastActiveAt,
    this.totalCo2Kg,
    this.points,
    this.streak,
    this.needsOnboarding = false,
    this.privacy,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      displayName: map['display_name'] as String?,
      email: map['email'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      country: map['country'] as String?,
      homeType: map['home_type'] as String?,
      dietType: map['diet_type'] as String?,
      householdSize: map['household_size'] as int?,
      preferredTransport: map['preferred_transport'] as String?,
      createdAt: map['created_at'] as Timestamp?,
      lastActiveAt: map['last_active_at'] as Timestamp?,
      totalCo2Kg: (map['total_co2_kg'] as num?)?.toDouble(),
      points: map['points'] is num ? (map['points'] as num).toInt() : int.tryParse(map['points']?.toString() ?? ''),
      streak: map['streak'] is num ? (map['streak'] as num).toInt() : int.tryParse(map['streak']?.toString() ?? ''),
      needsOnboarding: map['needs_onboarding'] as bool? ?? false,
      privacy: map['privacy'] != null
          ? PrivacySettings.fromMap(map['privacy'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'display_name': displayName,
      'email': email,
      'photo_url': photoUrl,
      'country': country,
      'home_type': homeType,
      'diet_type': dietType,
      'household_size': householdSize,
      'preferred_transport': preferredTransport,
      'created_at': createdAt,
      'last_active_at': lastActiveAt,
      'total_co2_kg': totalCo2Kg,
      'points': points,
      'streak': streak,
      'needs_onboarding': needsOnboarding,
      'privacy': privacy?.toMap(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? photoUrl,
    String? country,
    String? homeType,
    String? dietType,
    int? householdSize,
    String? preferredTransport,
    Timestamp? createdAt,
    Timestamp? lastActiveAt,
    double? totalCo2Kg,
    int? points,
    int? streak,
    PrivacySettings? privacy,
  }) {
    return UserModel(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      country: country ?? this.country,
      homeType: homeType ?? this.homeType,
      dietType: dietType ?? this.dietType,
      householdSize: householdSize ?? this.householdSize,
      preferredTransport: preferredTransport ?? this.preferredTransport,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      totalCo2Kg: totalCo2Kg ?? this.totalCo2Kg,
      points: points ?? this.points,
      streak: streak ?? this.streak,
      privacy: privacy ?? this.privacy,
    );
  }

  int get activeStreak {
    if (streak == null || streak == 0 || lastActiveAt == null) return 0;
    
    final now = DateTime.now().toUtc();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final yesterdayUtc = todayUtc.subtract(const Duration(days: 1));
    
    final lastActiveDate = lastActiveAt!.toDate().toUtc();
    final lastActiveDayUtc = DateTime.utc(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);

    if (lastActiveDayUtc.isAtSameMomentAs(todayUtc) || lastActiveDayUtc.isAtSameMomentAs(yesterdayUtc)) {
      return streak!;
    }
    return 0;
  }

  bool get isStreakAtRisk {
    if (activeStreak == 0 || lastActiveAt == null) return false;
    
    final now = DateTime.now().toUtc();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final yesterdayUtc = todayUtc.subtract(const Duration(days: 1));
    
    final lastActiveDate = lastActiveAt!.toDate().toUtc();
    final lastActiveDayUtc = DateTime.utc(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
    
    return lastActiveDayUtc.isAtSameMomentAs(yesterdayUtc);
  }
}

class PrivacySettings {
  final bool isPublic;
  final bool shareRank;
  final bool shareActivityDetails;

  PrivacySettings({
    this.isPublic = true,
    required this.shareRank,
    required this.shareActivityDetails,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      isPublic: map['is_public'] as bool? ?? true,
      shareRank: map['share_rank'] as bool? ?? true,
      shareActivityDetails: map['share_activity_details'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_public': isPublic,
      'share_rank': shareRank,
      'share_activity_details': shareActivityDetails,
    };
  }
}