import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/animated_timeline.dart';

abstract class TimelineRepository {
  Future<Either<Failure, AnimatedTimeline>> getAnimatedTimeline({
    required String token,
    required int userId,
    String timelineType = 'monthly',
    int periods = 12,
    bool includeForecast = true,
  });
}

