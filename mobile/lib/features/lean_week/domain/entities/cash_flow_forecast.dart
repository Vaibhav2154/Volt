import 'package:equatable/equatable.dart';
import 'forecast_period.dart';

class CashFlowForecast extends Equatable {
  final List<ForecastPeriod> forecasts;
  final List<String> warnings;
  final double confidence;
  final double incomeVolatility;
  final double avgMonthlyIncome;
  final double avgMonthlyExpenses;

  const CashFlowForecast({
    required this.forecasts,
    required this.warnings,
    required this.confidence,
    required this.incomeVolatility,
    required this.avgMonthlyIncome,
    required this.avgMonthlyExpenses,
  });

  @override
  List<Object?> get props => [
        forecasts,
        warnings,
        confidence,
        incomeVolatility,
        avgMonthlyIncome,
        avgMonthlyExpenses,
      ];
}







