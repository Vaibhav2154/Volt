import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../domain/entities/badge.dart' as gamification;

class BadgeCard extends StatelessWidget {
  final gamification.Badge badge;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.badge,
    this.onTap,
  });

  Color _getTierColor(String? tier) {
    if (tier == null) return ColorPalette.gray400;
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return ColorPalette.green400;
    }
  }

  IconData _getBadgeIcon(String code) {
    if (code.toLowerCase().contains('goal')) {
      return Icons.flag_rounded;
    } else if (code.toLowerCase().contains('transaction')) {
      return Icons.receipt_long_rounded;
    } else if (code.toLowerCase().contains('streak')) {
      return Icons.local_fire_department_rounded;
    } else if (code.toLowerCase().contains('level')) {
      return Icons.stars_rounded;
    } else {
      return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEarned = badge.isEarned;
    final tierColor = _getTierColor(badge.tier);
    final icon = _getBadgeIcon(badge.code);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isEarned
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tierColor.withOpacity(0.2),
                    tierColor.withOpacity(0.05),
                  ],
                )
              : null,
          color: isEarned ? null : theme.colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEarned
                ? tierColor.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? tierColor.withOpacity(0.2)
                        : theme.colorScheme.surface.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: isEarned
                        ? tierColor
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                if (!isEarned)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isEarned
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (badge.tier != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isEarned
                      ? tierColor.withOpacity(0.2)
                      : theme.colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge.tier!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isEarned
                        ? tierColor
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

