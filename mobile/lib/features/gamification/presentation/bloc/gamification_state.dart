import '../../domain/entities/gamification_feed.dart';
import '../../domain/entities/gamification_profile.dart';

abstract class GamificationState {}

class GamificationInitial extends GamificationState {}

class GamificationLoading extends GamificationState {}

class GamificationProfileLoaded extends GamificationState {
  final GamificationProfile profile;

  GamificationProfileLoaded(this.profile);
}

class GamificationFeedLoaded extends GamificationState {
  final GamificationFeed feed;

  GamificationFeedLoaded(this.feed);
}

class GamificationError extends GamificationState {
  final String message;

  GamificationError(this.message);
}

