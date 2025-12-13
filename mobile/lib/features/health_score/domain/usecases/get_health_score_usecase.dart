import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/financial_health_score.dart';
import '../repositories/health_score_repository.dart';

class GetHealthScoreParams {
  final String token;
  final int userId;

  GetHealthScoreParams({
    required this.token,
    required this.userId,
  });
}

class GetHealthScoreUseCase
    implements UseCase<FinancialHealthScore, GetHealthScoreParams> {
  final HealthScoreRepository repository;

  GetHealthScoreUseCase(this.repository);

  @override
  Future<Either<Failure, FinancialHealthScore>> call(
      GetHealthScoreParams params) async {
    return await repository.getHealthScore(
      token: params.token,
      userId: params.userId,
    );
  }
}

