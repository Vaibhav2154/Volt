import '../../domain/entities/cash_flow_forecast.dart';
import 'forecast_period_model.dart';

class CashFlowForecastModel extends CashFlowForecast {
  const CashFlowForecastModel({
    required super.forecasts,
    required super.warnings,
    required super.confidence,
    required super.incomeVolatility,
    required super.avgMonthlyIncome,
    required super.avgMonthlyExpenses,
  });

  factory CashFlowForecastModel.fromJson(Map<String, dynamic> json) {
    return CashFlowForecastModel(
      forecasts: (json['forecasts'] as List<dynamic>?)
              ?.map((e) => ForecastPeriodModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      incomeVolatility: (json['income_volatility'] as num?)?.toDouble() ?? 0.0,
      avgMonthlyIncome: (json['avg_monthly_income'] as num?)?.toDouble() ?? 0.0,
      avgMonthlyExpenses: (json['avg_monthly_expenses'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'forecasts': forecasts.map((e) => (e as ForecastPeriodModel).toJson()).toList(),
      'warnings': warnings,
      'confidence': confidence,
      'income_volatility': incomeVolatility,
      'avg_monthly_income': avgMonthlyIncome,
      'avg_monthly_expenses': avgMonthlyExpenses,
    };
  }
}







