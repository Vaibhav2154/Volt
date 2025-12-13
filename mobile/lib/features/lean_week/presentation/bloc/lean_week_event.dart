import 'package:equatable/equatable.dart';

abstract class LeanWeekEvent extends Equatable {
  const LeanWeekEvent();

  @override
  List<Object?> get props => [];
}

class GetLeanWeekAnalysisEvent extends LeanWeekEvent {
  final String token;
  final double? currentBalance;

  const GetLeanWeekAnalysisEvent({
    required this.token,
    this.currentBalance,
  });

  @override
  List<Object?> get props => [token, currentBalance];
}

class GetCashFlowForecastEvent extends LeanWeekEvent {
  final String token;
  final int periods;
  final double? currentBalance;

  const GetCashFlowForecastEvent({
    required this.token,
    this.periods = 3,
    this.currentBalance,
  });

  @override
  List<Object?> get props => [token, periods, currentBalance];
}

class GetIncomeSmoothingRecommendationsEvent extends LeanWeekEvent {
  final String token;
  final double? currentBalance;
  final int targetMonths;

  const GetIncomeSmoothingRecommendationsEvent({
    required this.token,
    this.currentBalance,
    this.targetMonths = 3,
  });

  @override
  List<Object?> get props => [token, currentBalance, targetMonths];
}







