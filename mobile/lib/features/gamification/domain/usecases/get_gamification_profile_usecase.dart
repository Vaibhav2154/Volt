import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/gamification_profile.dart';
import '../repositories/gamification_repository.dart';

class GetGamificationProfileUseCase {
  final GamificationRepository repository;

  GetGamificationProfileUseCase(this.repository);

  Future<Either<Failure, GamificationProfile>> call() async {
    return await repository.getProfile();
  }
}

