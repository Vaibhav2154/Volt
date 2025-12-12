import '../../domain/entities/badge.dart';

class BadgeModel extends Badge {
  const BadgeModel({
    required super.code,
    required super.name,
    super.description,
    super.tier,
    super.earnedAt,
    super.icon,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      tier: json['tier'] as String?,
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'] as String)
          : null,
      icon: json['icon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'tier': tier,
      'earned_at': earnedAt?.toIso8601String(),
      'icon': icon,
    };
  }
}

