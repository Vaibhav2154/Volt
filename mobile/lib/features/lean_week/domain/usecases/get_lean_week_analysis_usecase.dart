import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/lean_week_analysis.dart';
import '../repositories/lean_week_repository.dart';

class GetLeanWeekAnalysisUseCase
    implements UseCase<LeanWeekAnalysis, GetLeanWeekAnalysisParams> {
  final LeanWeekRepository repository;

  GetLeanWeekAnalysisUseCase(this.repository);

  @override
  Future<Either<Failure, LeanWeekAnalysis>> call(
      GetLeanWeekAnalysisParams params) async {
    return await repository.getLeanWeekAnalysis(
      token: params.token,
      currentBalance: params.currentBalance,
    );
  }
}

class GetLeanWeekAnalysisParams {
  final String token;
  final double? currentBalance;

  GetLeanWeekAnalysisParams({
    required this.token,
    this.currentBalance,
  });
}







