import '../../domain/entities/financial_health_score.dart';
import 'health_score_breakdown_model.dart';
import 'health_score_factors_model.dart';
import 'health_score_trend_model.dart';
import 'health_score_comparison_model.dart';
import 'health_score_recommendation_model.dart';

class FinancialHealthScoreModel extends FinancialHealthScore {
  const FinancialHealthScoreModel({
    required super.overallScore,
    required super.grade,
    required super.scoreDescription,
    required super.breakdown,
    required super.factors,
    super.comparison,
    required super.trend,
    required super.recommendations,
    required super.calculatedAt,
    required super.dataQuality,
  });

  factory FinancialHealthScoreModel.fromJson(Map<String, dynamic> json) {
    return FinancialHealthScoreModel(
      overallScore: (json['overall_score'] as num).toDouble(),
      grade: json['grade'] as String,
      scoreDescription: json['score_description'] as String,
      breakdown: HealthScoreBreakdownModel.fromJson(
        json['breakdown'] as Map<String, dynamic>,
      ),
      factors: HealthScoreFactorsModel.fromJson(
        json['factors'] as Map<String, dynamic>,
      ),
      comparison: json['comparison'] != null
          ? HealthScoreComparisonModel.fromJson(
              json['comparison'] as Map<String, dynamic>,
            )
          : null,
      trend: (json['trend'] as List<dynamic>?)
              ?.map((e) => HealthScoreTrendModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => HealthScoreRecommendationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      calculatedAt: DateTime.parse(json['calculated_at'] as String),
      dataQuality: json['data_quality'] as String,
    );
  }
}

