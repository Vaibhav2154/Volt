import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cash_flow_forecast.dart';
import '../entities/income_smoothing_recommendation.dart';
import '../entities/lean_week_analysis.dart';

abstract class LeanWeekRepository {
  Future<Either<Failure, LeanWeekAnalysis>> getLeanWeekAnalysis({
    required String token,
    double? currentBalance,
  });

  Future<Either<Failure, CashFlowForecast>> getCashFlowForecast({
    required String token,
    int periods = 3,
    double? currentBalance,
  });

  Future<Either<Failure, IncomeSmoothingRecommendation>>
      getIncomeSmoothingRecommendations({
    required String token,
    double? currentBalance,
    int targetMonths = 3,
  });
}






