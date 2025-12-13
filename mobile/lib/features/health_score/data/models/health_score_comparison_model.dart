import '../../domain/entities/health_score_comparison.dart';

class HealthScoreComparisonModel extends HealthScoreComparison {
  const HealthScoreComparisonModel({
    required super.percentile,
    required super.comparisonText,
    required super.avgScore,
  });

  factory HealthScoreComparisonModel.fromJson(Map<String, dynamic> json) {
    return HealthScoreComparisonModel(
      percentile: json['percentile'] as int,
      comparisonText: json['comparison_text'] as String,
      avgScore: (json['avg_score'] as num).toDouble(),
    );
  }
}

