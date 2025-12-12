import 'package:equatable/equatable.dart';
import '../../domain/entities/cash_flow_forecast.dart';
import '../../domain/entities/income_smoothing_recommendation.dart';
import '../../domain/entities/lean_week_analysis.dart';

abstract class LeanWeekState extends Equatable {
  const LeanWeekState();

  @override
  List<Object?> get props => [];
}

class LeanWeekInitial extends LeanWeekState {}

class LeanWeekLoading extends LeanWeekState {}

class LeanWeekAnalysisLoaded extends LeanWeekState {
  final LeanWeekAnalysis analysis;

  const LeanWeekAnalysisLoaded(this.analysis);

  @override
  List<Object?> get props => [analysis];
}

class CashFlowForecastLoaded extends LeanWeekState {
  final CashFlowForecast forecast;

  const CashFlowForecastLoaded(this.forecast);

  @override
  List<Object?> get props => [forecast];
}

class IncomeSmoothingRecommendationsLoaded extends LeanWeekState {
  final IncomeSmoothingRecommendation recommendations;

  const IncomeSmoothingRecommendationsLoaded(this.recommendations);

  @override
  List<Object?> get props => [recommendations];
}

class LeanWeekError extends LeanWeekState {
  final String message;

  const LeanWeekError(this.message);

  @override
  List<Object?> get props => [message];
}





