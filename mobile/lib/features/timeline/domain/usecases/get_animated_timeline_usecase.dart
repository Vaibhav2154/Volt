import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/animated_timeline.dart';
import '../repositories/timeline_repository.dart';

class GetAnimatedTimelineParams {
  final String token;
  final int userId;
  final String timelineType;
  final int periods;
  final bool includeForecast;

  GetAnimatedTimelineParams({
    required this.token,
    required this.userId,
    this.timelineType = 'monthly',
    this.periods = 12,
    this.includeForecast = true,
  });
}

class GetAnimatedTimelineUseCase
    implements UseCase<AnimatedTimeline, GetAnimatedTimelineParams> {
  final TimelineRepository repository;

  GetAnimatedTimelineUseCase(this.repository);

  @override
  Future<Either<Failure, AnimatedTimeline>> call(
      GetAnimatedTimelineParams params) async {
    return await repository.getAnimatedTimeline(
      token: params.token,
      userId: params.userId,
      timelineType: params.timelineType,
      periods: params.periods,
      includeForecast: params.includeForecast,
    );
  }
}

