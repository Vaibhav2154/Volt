import '../../domain/entities/income_smoothing_recommendation.dart';
import 'smoothing_strategy_model.dart';

class IncomeSmoothingRecommendationModel
    extends IncomeSmoothingRecommendation {
  const IncomeSmoothingRecommendationModel({
    required super.currentBalance,
    required super.targetEmergencyFund,
    required super.emergencyFundGap,
    required super.avgMonthlyIncome,
    required super.avgMonthlyExpenses,
    required super.incomeVolatility,
    required super.goodMonthsCount,
    required super.leanMonthsCount,
    required super.recommendedSaveRate,
    required super.monthlySaveAmount,
    super.monthsToTarget,
    required super.strategy,
  });

  factory IncomeSmoothingRecommendationModel.fromJson(
      Map<String, dynamic> json) {
    return IncomeSmoothingRecommendationModel(
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      targetEmergencyFund:
          (json['target_emergency_fund'] as num?)?.toDouble() ?? 0.0,
      emergencyFundGap: (json['emergency_fund_gap'] as num?)?.toDouble() ?? 0.0,
      avgMonthlyIncome:
          (json['avg_monthly_income'] as num?)?.toDouble() ?? 0.0,
      avgMonthlyExpenses:
          (json['avg_monthly_expenses'] as num?)?.toDouble() ?? 0.0,
      incomeVolatility:
          (json['income_volatility'] as num?)?.toDouble() ?? 0.0,
      goodMonthsCount: json['good_months_count'] as int? ?? 0,
      leanMonthsCount: json['lean_months_count'] as int? ?? 0,
      recommendedSaveRate:
          (json['recommended_save_rate'] as num?)?.toDouble() ?? 0.0,
      monthlySaveAmount:
          (json['monthly_save_amount'] as num?)?.toDouble() ?? 0.0,
      monthsToTarget: json['months_to_target'] != null
          ? (json['months_to_target'] as num).toDouble()
          : null,
      strategy: SmoothingStrategyModel.fromJson(
        json['strategy'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_balance': currentBalance,
      'target_emergency_fund': targetEmergencyFund,
      'emergency_fund_gap': emergencyFundGap,
      'avg_monthly_income': avgMonthlyIncome,
      'avg_monthly_expenses': avgMonthlyExpenses,
      'income_volatility': incomeVolatility,
      'good_months_count': goodMonthsCount,
      'lean_months_count': leanMonthsCount,
      'recommended_save_rate': recommendedSaveRate,
      'monthly_save_amount': monthlySaveAmount,
      'months_to_target': monthsToTarget,
      'strategy': (strategy as SmoothingStrategyModel).toJson(),
    };
  }
}





