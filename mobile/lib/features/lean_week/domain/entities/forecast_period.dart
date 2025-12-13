import 'package:equatable/equatable.dart';
import 'cash_flow_scenario.dart';

class ForecastPeriod extends Equatable {
  final int period;
  final int monthOffset;
  final CashFlowScenario income;
  final CashFlowScenario expenses;
  final CashFlowScenario netCashFlow;
  final CashFlowScenario projectedBalance;
  final bool isLeanPeriod;
  final bool balanceAtRisk;

  const ForecastPeriod({
    required this.period,
    required this.monthOffset,
    required this.income,
    required this.expenses,
    required this.netCashFlow,
    required this.projectedBalance,
    required this.isLeanPeriod,
    required this.balanceAtRisk,
  });

  @override
  List<Object?> get props => [
        period,
        monthOffset,
        income,
        expenses,
        netCashFlow,
        projectedBalance,
        isLeanPeriod,
        balanceAtRisk,
      ];
}







