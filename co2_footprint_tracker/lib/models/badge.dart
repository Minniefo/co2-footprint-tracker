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
      title: map['title'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      criteria: map['criteria'] as Map<String, dynamic>? ?? {},
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
