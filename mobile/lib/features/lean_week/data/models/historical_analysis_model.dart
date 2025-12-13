import '../../domain/entities/historical_analysis.dart';
import 'lean_analysis_model.dart';

class HistoricalAnalysisModel extends HistoricalAnalysis {
  const HistoricalAnalysisModel({
    required super.monthly,
    required super.weekly,
  });

  factory HistoricalAnalysisModel.fromJson(Map<String, dynamic> json) {
    return HistoricalAnalysisModel(
      monthly: LeanAnalysisModel.fromJson(json['monthly'] as Map<String, dynamic>),
      weekly: LeanAnalysisModel.fromJson(json['weekly'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly': (monthly as LeanAnalysisModel).toJson(),
      'weekly': (weekly as LeanAnalysisModel).toJson(),
    };
  }
}






