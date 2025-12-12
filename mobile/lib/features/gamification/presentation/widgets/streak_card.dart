import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../domain/entities/streak.dart';

class StreakCard extends StatelessWidget {
  final Streak streak;

  const StreakCard({
    super.key,
    required this.streak,
  });

  String _getStreakIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
        return '🔥';
      case 'categorization':
        return '📊';
      case 'no_spend':
        return '💰';
      default:
        return '⚡';
    }
  }

  String _getStreakLabel(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
        return 'Check-in';
      case 'categorization':
        return 'Categorization';
      case 'no_spend':
        return 'No-Spend';
      default:
        return type;
    }
  }

  Color _getStreakColor(String type) {
    switch (type.toLowerCase()) {
      case 'checkin':
        return ColorPalette.warning;
      case 'categorization':
        return ColorPalette.info;
      case 'no_spend':
        return ColorPalette.success;
      default:
        return ColorPalette.green400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStreakColor(streak.type);
    final icon = _getStreakIcon(streak.type);
    final label = _getStreakLabel(streak.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${streak.count} days',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (streak.nextBonusIn != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.celebration_outlined,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${streak.nextBonusIn} days to bonus',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

