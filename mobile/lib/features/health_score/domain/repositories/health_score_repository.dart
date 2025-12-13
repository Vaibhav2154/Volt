import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/financial_health_score.dart';

abstract class HealthScoreRepository {
  Future<Either<Failure, FinancialHealthScore>> getHealthScore({
    required String token,
    required int userId,
  });
}

