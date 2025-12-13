import 'package:equatable/equatable.dart';

abstract class TimelineEvent extends Equatable {
  const TimelineEvent();

  @override
  List<Object?> get props => [];
}

class LoadTimelineEvent extends TimelineEvent {
  final String token;
  final int userId;
  final String timelineType;
  final int periods;
  final bool includeForecast;

  const LoadTimelineEvent({
    required this.token,
    required this.userId,
    this.timelineType = 'monthly',
    this.periods = 12,
    this.includeForecast = true,
  });

  @override
  List<Object?> get props => [token, userId, timelineType, periods, includeForecast];
}

class RefreshTimelineEvent extends TimelineEvent {
  final String token;
  final int userId;
  final String timelineType;
  final int periods;
  final bool includeForecast;

  const RefreshTimelineEvent({
    required this.token,
    required this.userId,
    this.timelineType = 'monthly',
    this.periods = 12,
    this.includeForecast = true,
  });

  @override
  List<Object?> get props => [token, userId, timelineType, periods, includeForecast];
}

