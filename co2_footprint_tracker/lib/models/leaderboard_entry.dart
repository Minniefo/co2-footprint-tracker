class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int points;
  final double co2SavedKg;
  final int rank;
  final String? photoUrl;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.points,
    required this.co2SavedKg,
    required this.rank,
    this.photoUrl,
  });

  factory LeaderboardEntry.fromMap(String id, Map<String, dynamic> map) {
    return LeaderboardEntry(
      userId: map['user_id'] as String? ?? id,
      displayName: map['display_name'] as String? ?? 'Anonymous',
      points: (map['points'] as num?)?.toInt() ?? 0,
      co2SavedKg: (map['co2_saved_kg'] as num?)?.toDouble() ?? 0.0,
      rank: (map['rank'] as num?)?.toInt() ?? 999,
      photoUrl: map['photo_url'] as String?,
    );
  }
}
