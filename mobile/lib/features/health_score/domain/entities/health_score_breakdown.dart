import 'package:equatable/equatable.dart';

class HealthScoreBreakdown extends Equatable {
  final double incomeStability;
  final double spendingDiscipline;
  final double emergencyFund;
  final double savingsRate;
  final double debtHealth;
  final double diversification;

  const HealthScoreBreakdown({
    required this.incomeStability,
    required this.spendingDiscipline,
    required this.emergencyFund,
    required this.savingsRate,
    required this.debtHealth,
    required this.diversification,
  });

  @override
  List<Object?> get props => [
        incomeStability,
        spendingDiscipline,
        emergencyFund,
        savingsRate,
        debtHealth,
        diversification,
      ];
}

