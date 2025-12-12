import '../../domain/entities/gamification_profile.dart';
import 'badge_model.dart';
import 'streak_model.dart';

class GamificationProfileModel extends GamificationProfile {
  const GamificationProfileModel({
    required super.xpTotal,
    required super.level,
    required super.nextLevelXp,
    required super.xpToNextLevel,
    required super.streaks,
    required super.badges,
  });

  factory GamificationProfileModel.fromJson(Map<String, dynamic> json) {
    return GamificationProfileModel(
      xpTotal: json['xp_total'] as int,
      level: json['level'] as int,
      nextLevelXp: json['next_level_xp'] as int,
      xpToNextLevel: json['xp_to_next_level'] as int,
      streaks: (json['streaks'] as List<dynamic>?)
              ?.map((e) => StreakModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'xp_total': xpTotal,
      'level': level,
      'next_level_xp': nextLevelXp,
      'xp_to_next_level': xpToNextLevel,
      'streaks': streaks.map((s) => (s as StreakModel).toJson()).toList(),
      'badges': badges.map((b) => (b as BadgeModel).toJson()).toList(),
    };
  }
}

