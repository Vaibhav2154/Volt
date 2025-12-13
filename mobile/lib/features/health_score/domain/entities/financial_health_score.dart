import 'package:equatable/equatable.dart';
import 'health_score_breakdown.dart';
import 'health_score_factors.dart';
import 'health_score_trend.dart';
import 'health_score_comparison.dart';
import 'health_score_recommendation.dart';

class FinancialHealthScore extends Equatable {
  final double overallScore;
  final String grade; // 'A+', 'A', 'A-', etc.
  final String scoreDescription;
  final HealthScoreBreakdown breakdown;
  final HealthScoreFactors factors;
  final HealthScoreComparison? comparison;
  final List<HealthScoreTrend> trend;
  final List<HealthScoreRecommendation> recommendations;
  final DateTime calculatedAt;
  final String dataQuality; // 'excellent', 'good', 'fair', 'poor'

  const FinancialHealthScore({
    required this.overallScore,
    required this.grade,
    required this.scoreDescription,
    required this.breakdown,
    required this.factors,
    this.comparison,
    required this.trend,
    required this.recommendations,
    required this.calculatedAt,
    required this.dataQuality,
  });

  @override
  List<Object?> get props => [
        overallScore,
        grade,
        scoreDescription,
        breakdown,
        factors,
        comparison,
        trend,
        recommendations,
        calculatedAt,
        dataQuality,
      ];
}

