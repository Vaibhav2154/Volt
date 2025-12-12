class Badge {
  final String code;
  final String name;
  final String? description;
  final String? tier;
  final DateTime? earnedAt;
  final String? icon;

  const Badge({
    required this.code,
    required this.name,
    this.description,
    this.tier,
    this.earnedAt,
    this.icon,
  });

  bool get isEarned => earnedAt != null;
}

