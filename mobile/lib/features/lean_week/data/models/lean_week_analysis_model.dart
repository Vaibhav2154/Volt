import '../../domain/entities/lean_week_analysis.dart';
import 'cash_flow_forecast_model.dart';
import 'historical_analysis_model.dart';
import 'income_smoothing_recommendation_model.dart';
import 'risk_summary_model.dart';

class LeanWeekAnalysisModel extends LeanWeekAnalysis {
  const LeanWeekAnalysisModel({
    required super.summary,
    required super.historicalAnalysis,
    required super.cashFlowForecast,
    required super.incomeSmoothing,
    required super.generatedAt,
  });

  factory LeanWeekAnalysisModel.fromJson(Map<String, dynamic> json) {
    return LeanWeekAnalysisModel(
      summary: RiskSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      historicalAnalysis: HistoricalAnalysisModel.fromJson(
        json['historical_analysis'] as Map<String, dynamic>,
      ),
      cashFlowForecast: CashFlowForecastModel.fromJson(
        json['cash_flow_forecast'] as Map<String, dynamic>,
      ),
      incomeSmoothing: IncomeSmoothingRecommendationModel.fromJson(
        json['income_smoothing'] as Map<String, dynamic>,
      ),
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': (summary as RiskSummaryModel).toJson(),
      'historical_analysis':
          (historicalAnalysis as HistoricalAnalysisModel).toJson(),
      'cash_flow_forecast':
          (cashFlowForecast as CashFlowForecastModel).toJson(),
      'income_smoothing':
          (incomeSmoothing as IncomeSmoothingRecommendationModel).toJson(),
      'generated_at': generatedAt,
    };
  }
}





