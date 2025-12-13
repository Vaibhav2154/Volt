import 'package:equatable/equatable.dart';

class CashFlowPeriod extends Equatable {
  final String periodKey;
  final DateTime startDate;
  final DateTime endDate;
  final double income;
  final double expenses;
  final double netFlow;
  final bool isLean;
  final double? severity;
  final int incomeSources;
  final int transactionCount;
  final int animationDelay;
  final bool highlight;

  const CashFlowPeriod({
    required this.periodKey,
    required this.startDate,
    required this.endDate,
    required this.income,
    required this.expenses,
    required this.netFlow,
    this.isLean = false,
    this.severity,
    this.incomeSources = 0,
    this.transactionCount = 0,
    this.animationDelay = 0,
    this.highlight = false,
  });

  @override
  List<Object?> get props => [
        periodKey,
        startDate,
        endDate,
        income,
        expenses,
        netFlow,
        isLean,
        severity,
        incomeSources,
        transactionCount,
        animationDelay,
        highlight,
      ];
}

