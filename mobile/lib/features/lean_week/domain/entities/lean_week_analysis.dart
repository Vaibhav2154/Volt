import 'package:equatable/equatable.dart';
import 'cash_flow_forecast.dart';
import 'historical_analysis.dart';
import 'income_smoothing_recommendation.dart';
import 'risk_summary.dart';

class LeanWeekAnalysis extends Equatable {
  final RiskSummary summary;
  final HistoricalAnalysis historicalAnalysis;
  final CashFlowForecast cashFlowForecast;
  final IncomeSmoothingRecommendation incomeSmoothing;
  final String generatedAt;

  const LeanWeekAnalysis({
    required this.summary,
    required this.historicalAnalysis,
    required this.cashFlowForecast,
    required this.incomeSmoothing,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
        summary,
        historicalAnalysis,
        cashFlowForecast,
        incomeSmoothing,
        generatedAt,
      ];
}






