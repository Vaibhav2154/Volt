import '../../domain/entities/scenario_comparison.dart';

class ScenarioSummaryModel extends ScenarioSummary {
  const ScenarioSummaryModel({
    required super.scenarioId,
    required super.name,
    required super.description,
    required super.scenarioType,
    required super.targetPercent,
    required super.achievablePercent,
    required super.baselineMonthly,
    required super.projectedMonthly,
    required super.totalChange,
    required super.annualImpact,
    required super.feasibility,
    required super.difficultyScore,
    required super.topCategories,
    required super.keyInsight,
  });

  factory ScenarioSummaryModel.fromJson(Map<String, dynamic> json) {
    // Handle both string and num types for decimal fields
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      return 0.0;
    }

    return ScenarioSummaryModel(
      scenarioId: json['scenario_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      scenarioType: json['scenario_type'] as String,
      targetPercent: (json['target_percent'] as num).toDouble(),
      achievablePercent: (json['achievable_percent'] as num).toDouble(),
      baselineMonthly: parseAmount(json['baseline_monthly']),
      projectedMonthly: parseAmount(json['projected_monthly']),
      totalChange: parseAmount(json['total_change']),
      annualImpact: parseAmount(json['annual_impact']),
      feasibility: json['feasibility'] as String,
      difficultyScore: (json['difficulty_score'] as num).toDouble(),
      topCategories: (json['top_categories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      keyInsight: json['key_insight'] as String,
    );
  }
}

class ScenarioComparisonResponseModel extends ScenarioComparisonResponse {
  const ScenarioComparisonResponseModel({
    required super.scenarioType,
    required super.baselineMonthly,
    required super.timePeriodDays,
    required super.scenarios,
    required super.recommendedScenarioId,
    required super.comparisonChart,
    required super.insights,
  });

  factory ScenarioComparisonResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle both string and num types for decimal fields
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      return 0.0;
    }

    return ScenarioComparisonResponseModel(
      scenarioType: json['scenario_type'] as String,
      baselineMonthly: parseAmount(json['baseline_monthly']),
      timePeriodDays: json['time_period_days'] as int,
      scenarios: (json['scenarios'] as List<dynamic>)
          .map((e) => ScenarioSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedScenarioId: json['recommended_scenario_id'] as String,
      comparisonChart: json['comparison_chart'] as Map<String, dynamic>,
      insights: (json['insights'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}







