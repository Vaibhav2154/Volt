import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/gamification_feed.dart';
import '../repositories/gamification_repository.dart';

class GetGamificationFeedUseCase {
  final GamificationRepository repository;

  GetGamificationFeedUseCase(this.repository);

  Future<Either<Failure, GamificationFeed>> call({int limit = 20}) async {
    return await repository.getFeed(limit: limit);
  }
}

