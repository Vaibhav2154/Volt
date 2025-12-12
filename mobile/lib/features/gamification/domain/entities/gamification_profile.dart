import 'badge.dart';
import 'streak.dart';

class GamificationProfile {
  final int xpTotal;
  final int level;
  final int nextLevelXp;
  final int xpToNextLevel;
  final List<Streak> streaks;
  final List<Badge> badges;

  const GamificationProfile({
    required this.xpTotal,
    required this.level,
    required this.nextLevelXp,
    required this.xpToNextLevel,
    required this.streaks,
    required this.badges,
  });
}

