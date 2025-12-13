import '../../domain/entities/health_score_recommendation.dart';

class HealthScoreRecommendationModel extends HealthScoreRecommendation {
  const HealthScoreRecommendationModel({
    required super.priority,
    required super.action,
    required super.impact,
    required super.difficulty,
    required super.estimatedScoreGain,
  });

  factory HealthScoreRecommendationModel.fromJson(Map<String, dynamic> json) {
    return HealthScoreRecommendationModel(
      priority: json['priority'] as String,
      action: json['action'] as String,
      impact: json['impact'] as String,
      difficulty: json['difficulty'] as String,
      estimatedScoreGain: (json['estimated_score_gain'] as num).toDouble(),
    );
  }
}

