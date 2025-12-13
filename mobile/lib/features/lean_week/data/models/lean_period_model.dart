import '../../domain/entities/lean_period.dart';

class LeanPeriodModel extends LeanPeriod {
  const LeanPeriodModel({
    required super.period,
    required super.netFlow,
    required super.income,
    required super.expenses,
    required super.severity,
    super.startDate,
  });

  factory LeanPeriodModel.fromJson(Map<String, dynamic> json) {
    DateTime? startDate;
    if (json['start_date'] != null) {
      try {
        startDate = DateTime.parse(json['start_date'] as String);
      } catch (e) {
        startDate = null;
      }
    }

    return LeanPeriodModel(
      period: json['period'] as String,
      netFlow: (json['net_flow'] as num).toDouble(),
      income: (json['income'] as num).toDouble(),
      expenses: (json['expenses'] as num).toDouble(),
      severity: (json['severity'] as num).toDouble(),
      startDate: startDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'net_flow': netFlow,
      'income': income,
      'expenses': expenses,
      'severity': severity,
      'start_date': startDate?.toIso8601String(),
    };
  }
}






