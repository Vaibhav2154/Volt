import 'gamification_event.dart';

class GamificationFeed {
  final List<GamificationEvent> events;
  final int totalCount;

  const GamificationFeed({
    required this.events,
    required this.totalCount,
  });
}

