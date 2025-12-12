import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/gamification_feed.dart';
import '../entities/gamification_profile.dart';

abstract class GamificationRepository {
  Future<Either<Failure, GamificationProfile>> getProfile();
  Future<Either<Failure, GamificationFeed>> getFeed({int limit = 20});
}

