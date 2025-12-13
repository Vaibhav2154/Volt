import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cash_flow_forecast.dart';
import '../repositories/lean_week_repository.dart';

class GetCashFlowForecastUseCase
    implements UseCase<CashFlowForecast, GetCashFlowForecastParams> {
  final LeanWeekRepository repository;

  GetCashFlowForecastUseCase(this.repository);

  @override
  Future<Either<Failure, CashFlowForecast>> call(
      GetCashFlowForecastParams params) async {
    return await repository.getCashFlowForecast(
      token: params.token,
      periods: params.periods,
      currentBalance: params.currentBalance,
    );
  }
}

class GetCashFlowForecastParams {
  final String token;
  final int periods;
  final double? currentBalance;

  GetCashFlowForecastParams({
    required this.token,
    this.periods = 3,
    this.currentBalance,
  });
}







