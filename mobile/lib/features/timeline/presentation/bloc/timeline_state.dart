import 'package:equatable/equatable.dart';
import '../../domain/entities/animated_timeline.dart';

abstract class TimelineState extends Equatable {
  const TimelineState();

  @override
  List<Object?> get props => [];
}

class TimelineInitial extends TimelineState {}

class TimelineLoading extends TimelineState {}

class TimelineLoaded extends TimelineState {
  final AnimatedTimeline timeline;

  const TimelineLoaded(this.timeline);

  @override
  List<Object?> get props => [timeline];
}

class TimelineError extends TimelineState {
  final String message;

  const TimelineError(this.message);

  @override
  List<Object?> get props => [message];
}

