import '../../domain/entities/gamification_feed.dart';
import 'gamification_event_model.dart';

class GamificationFeedModel extends GamificationFeed {
  const GamificationFeedModel({
    required super.events,
    required super.totalCount,
  });

  factory GamificationFeedModel.fromJson(Map<String, dynamic> json) {
    return GamificationFeedModel(
      events: (json['events'] as List<dynamic>)
          .map((e) => GamificationEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => (e as GamificationEventModel).toJson()).toList(),
      'total_count': totalCount,
    };
  }
}

