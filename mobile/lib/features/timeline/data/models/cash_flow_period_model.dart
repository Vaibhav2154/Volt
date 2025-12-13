import '../../domain/entities/cash_flow_period.dart';

class CashFlowPeriodModel extends CashFlowPeriod {
  const CashFlowPeriodModel({
    required super.periodKey,
    required super.startDate,
    required super.endDate,
    required super.income,
    required super.expenses,
    required super.netFlow,
    super.isLean,
    super.severity,
    super.incomeSources,
    super.transactionCount,
    super.animationDelay,
    super.highlight,
  });

  factory CashFlowPeriodModel.fromJson(Map<String, dynamic> json) {
    return CashFlowPeriodModel(
      periodKey: json['period_key'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      income: (json['income'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
      netFlow: (json['net_flow'] as num).toDouble(),
      isLean: json['is_lean'] as bool? ?? false,
      severity: json['severity'] != null ? (json['severity'] as num).toDouble() : null,
      incomeSources: json['income_sources'] as int? ?? 0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      animationDelay: json['animation_delay'] as int? ?? 0,
      highlight: json['highlight'] as bool? ?? false,
    );
  }
}

