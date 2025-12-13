import 'package:equatable/equatable.dart';

class LeanPeriod extends Equatable {
  final String period;
  final double netFlow;
  final double income;
  final double expenses;
  final double severity;
  final DateTime? startDate;

  const LeanPeriod({
    required this.period,
    required this.netFlow,
    required this.income,
    required this.expenses,
    required this.severity,
    this.startDate,
  });

  @override
  List<Object?> get props => [
        period,
        netFlow,
        income,
        expenses,
        severity,
        startDate,
      ];
}







