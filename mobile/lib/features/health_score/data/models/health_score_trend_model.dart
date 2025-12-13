import '../../domain/entities/health_score_trend.dart';

class HealthScoreTrendModel extends HealthScoreTrend {
  const HealthScoreTrendModel({
    required super.date,
    required super.score,
    super.change,
  });

  factory HealthScoreTrendModel.fromJson(Map<String, dynamic> json) {
    return HealthScoreTrendModel(
      date: DateTime.parse(json['date'] as String),
      score: (json['score'] as num).toDouble(),
      change: json['change'] != null ? (json['change'] as num).toDouble() : null,
    );
  }
}

