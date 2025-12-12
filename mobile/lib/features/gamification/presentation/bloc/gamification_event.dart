abstract class GamificationEvent {}

class LoadGamificationProfileEvent extends GamificationEvent {}

class RefreshGamificationProfileEvent extends GamificationEvent {}

class LoadGamificationFeedEvent extends GamificationEvent {
  final int limit;

  LoadGamificationFeedEvent({this.limit = 20});
}

