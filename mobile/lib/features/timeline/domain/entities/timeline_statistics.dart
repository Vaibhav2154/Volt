import 'package:equatable/equatable.dart';

class TimelineStatistics extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double totalNetFlow;
  final double avgNetFlow;
  final int leanPeriodCount;
  final double leanFrequency;
  final double volatility;

  const TimelineStatistics({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalNetFlow,
    required this.avgNetFlow,
    required this.leanPeriodCount,
    required this.leanFrequency,
    required this.volatility,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpenses,
        totalNetFlow,
        avgNetFlow,
        leanPeriodCount,
        leanFrequency,
        volatility,
      ];
}

