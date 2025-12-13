import 'package:equatable/equatable.dart';
import 'smoothing_strategy.dart';

class IncomeSmoothingRecommendation extends Equatable {
  final double currentBalance;
  final double targetEmergencyFund;
  final double emergencyFundGap;
  final double avgMonthlyIncome;
  final double avgMonthlyExpenses;
  final double incomeVolatility;
  final int goodMonthsCount;
  final int leanMonthsCount;
  final double recommendedSaveRate;
  final double monthlySaveAmount;
  final double? monthsToTarget;
  final SmoothingStrategy strategy;

  const IncomeSmoothingRecommendation({
    required this.currentBalance,
    required this.targetEmergencyFund,
    required this.emergencyFundGap,
    required this.avgMonthlyIncome,
    required this.avgMonthlyExpenses,
    required this.incomeVolatility,
    required this.goodMonthsCount,
    required this.leanMonthsCount,
    required this.recommendedSaveRate,
    required this.monthlySaveAmount,
    this.monthsToTarget,
    required this.strategy,
  });

  @override
  List<Object?> get props => [
        currentBalance,
        targetEmergencyFund,
        emergencyFundGap,
        avgMonthlyIncome,
        avgMonthlyExpenses,
        incomeVolatility,
        goodMonthsCount,
        leanMonthsCount,
        recommendedSaveRate,
        monthlySaveAmount,
        monthsToTarget,
        strategy,
      ];
}






