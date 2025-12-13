import '../../domain/entities/health_score_factors.dart';

class HealthScoreFactorsModel extends HealthScoreFactors {
  const HealthScoreFactorsModel({
    required super.positiveFactors,
    required super.negativeFactors,
    required super.criticalIssues,
  });

  factory HealthScoreFactorsModel.fromJson(Map<String, dynamic> json) {
    return HealthScoreFactorsModel(
      positiveFactors: (json['positive_factors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      negativeFactors: (json['negative_factors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      criticalIssues: (json['critical_issues'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

