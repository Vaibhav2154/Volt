import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/income_smoothing_recommendation.dart';
import '../repositories/lean_week_repository.dart';

class GetIncomeSmoothingRecommendationsUseCase
    implements
        UseCase<IncomeSmoothingRecommendation,
            GetIncomeSmoothingRecommendationsParams> {
  final LeanWeekRepository repository;

  GetIncomeSmoothingRecommendationsUseCase(this.repository);

  @override
  Future<Either<Failure, IncomeSmoothingRecommendation>> call(
      GetIncomeSmoothingRecommendationsParams params) async {
    return await repository.getIncomeSmoothingRecommendations(
      token: params.token,
      currentBalance: params.currentBalance,
      targetMonths: params.targetMonths,
    );
  }
}

class GetIncomeSmoothingRecommendationsParams {
  final String token;
  final double? currentBalance;
  final int targetMonths;

  GetIncomeSmoothingRecommendationsParams({
    required this.token,
    this.currentBalance,
    this.targetMonths = 3,
  });
}






