import '../../domain/entities/health_score_breakdown.dart';

class HealthScoreBreakdownModel extends HealthScoreBreakdown {
  const HealthScoreBreakdownModel({
    required super.incomeStability,
    required super.spendingDiscipline,
    required super.emergencyFund,
    required super.savingsRate,
    required super.debtHealth,
    required super.diversification,
  });

  factory HealthScoreBreakdownModel.fromJson(Map<String, dynamic> json) {
    return HealthScoreBreakdownModel(
      incomeStability: (json['income_stability'] as num).toDouble(),
      spendingDiscipline: (json['spending_discipline'] as num).toDouble(),
      emergencyFund: (json['emergency_fund'] as num).toDouble(),
      savingsRate: (json['savings_rate'] as num).toDouble(),
      debtHealth: (json['debt_health'] as num).toDouble(),
      diversification: (json['diversification'] as num).toDouble(),
    );
  }
}

