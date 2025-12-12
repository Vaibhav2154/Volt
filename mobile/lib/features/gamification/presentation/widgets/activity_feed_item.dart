import 'package:flutter/material.dart';
import '../../../../core/theme/app_pallette.dart';
import '../../domain/entities/gamification_event.dart';

class ActivityFeedItem extends StatelessWidget {
  final GamificationEvent event;

  const ActivityFeedItem({
    super.key,
    required this.event,
  });

  String _getEventIcon(String eventType) {
    if (eventType.toLowerCase().contains('checkin')) {
      return '📅';
    } else if (eventType.toLowerCase().contains('transaction')) {
      return '💳';
    } else if (eventType.toLowerCase().contains('goal')) {
      return '🎯';
    } else if (eventType.toLowerCase().contains('streak')) {
      return '🔥';
    } else if (eventType.toLowerCase().contains('badge')) {
      return '🏆';
    } else {
      return '⭐';
    }
  }

  String _getEventMessage(String eventType) {
    if (event.message != null && event.message!.isNotEmpty) {
      return event.message!;
    }

    // Fallback to default messages
    if (eventType.toLowerCase().contains('checkin')) {
      return 'Daily check-in completed';
    } else if (eventType.toLowerCase().contains('transaction')) {
      return 'Transaction imported';
    } else if (eventType.toLowerCase().contains('goal')) {
      return 'Goal milestone reached';
    } else if (eventType.toLowerCase().contains('streak')) {
      return 'Streak bonus earned';
    } else if (eventType.toLowerCase().contains('badge')) {
      return 'Badge unlocked';
    } else {
      return 'XP earned';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getEventIcon(event.eventType);
    final message = _getEventMessage(event.eventType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorPalette.green400.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(event.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ColorPalette.green400.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 16,
                  color: ColorPalette.green400,
                ),
                const SizedBox(width: 4),
                Text(
                  '+${event.xpAwarded}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.green400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

