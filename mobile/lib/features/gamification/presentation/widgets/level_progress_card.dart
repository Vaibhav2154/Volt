import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallette.dart';

class LevelProgressCard extends StatelessWidget {
  final int level;
  final int xpTotal;
  final int xpToNextLevel;
  final int nextLevelXp;

  const LevelProgressCard({
    super.key,
    required this.level,
    required this.xpTotal,
    required this.xpToNextLevel,
    required this.nextLevelXp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = nextLevelXp > 0
        ? (xpTotal - (xpTotal - xpToNextLevel)) / nextLevelXp
        : 0.0;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorPalette.green400.withOpacity(0.2),
            ColorPalette.green400.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ColorPalette.green400.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $level',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xpTotal XP',
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorPalette.green400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorPalette.green400.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorPalette.green400.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.stars_rounded,
                  color: ColorPalette.green400,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to Level ${level + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$xpToNextLevel / $nextLevelXp XP',
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorPalette.green400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: clampedProgress,
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ColorPalette.green400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

