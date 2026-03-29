class BadgeModel {
  final String badgeId;
  final String title;
  final String description;
  final String icon;
  final Map<String, dynamic> criteria;

  BadgeModel({
    required this.badgeId,
    required this.title,
    required this.description,
    required this.icon,
    required this.criteria,
  });

  factory BadgeModel.fromMap(String id, Map<String, dynamic> map) {
    return BadgeModel(
      badgeId: id,
      title: map['title'] as String? ?? 'Unknown Badge',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? '🏆',
      criteria: map['criteria'] != null 
          ? Map<String, dynamic>.from(map['criteria'] as Map) 
          : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'criteria': criteria,
    };
  }
}
