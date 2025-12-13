import '../../domain/entities/forecast_period.dart';
import 'cash_flow_scenario_model.dart';

class ForecastPeriodModel extends ForecastPeriod {
  const ForecastPeriodModel({
    required super.period,
    required super.monthOffset,
    required super.income,
    required super.expenses,
    required super.netCashFlow,
    required super.projectedBalance,
    required super.isLeanPeriod,
    required super.balanceAtRisk,
  });

  factory ForecastPeriodModel.fromJson(Map<String, dynamic> json) {
    return ForecastPeriodModel(
      period: json['period'] as int,
      monthOffset: json['month_offset'] as int,
      income: CashFlowScenarioModel.fromJson(json['income'] as Map<String, dynamic>),
      expenses: CashFlowScenarioModel.fromJson(json['expenses'] as Map<String, dynamic>),
      netCashFlow: CashFlowScenarioModel.fromJson(json['net_cash_flow'] as Map<String, dynamic>),
      projectedBalance: CashFlowScenarioModel.fromJson(json['projected_balance'] as Map<String, dynamic>),
      isLeanPeriod: json['is_lean_period'] as bool? ?? false,
      balanceAtRisk: json['balance_at_risk'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'month_offset': monthOffset,
      'income': (income as CashFlowScenarioModel).toJson(),
      'expenses': (expenses as CashFlowScenarioModel).toJson(),
      'net_cash_flow': (netCashFlow as CashFlowScenarioModel).toJson(),
      'projected_balance': (projectedBalance as CashFlowScenarioModel).toJson(),
      'is_lean_period': isLeanPeriod,
      'balance_at_risk': balanceAtRisk,
    };
  }
}






