import '../../domain/entities/scenario_insight.dart';

class QuickWinModel extends QuickWin {
  const QuickWinModel({
    required super.category,
    required super.categoryKey,
    required super.action,
    required super.monthlyImpact,
    required super.annualImpact,
    required super.difficulty,
    required super.currentSpending,
    required super.newSpending,
    super.reason,
  });

  factory QuickWinModel.fromJson(Map<String, dynamic> json) {
    return QuickWinModel(
      category: json['category'] as String,
      categoryKey: json['category_key'] as String,
      action: json['action'] as String,
      monthlyImpact: (json['monthly_impact'] as num).toDouble(),
      annualImpact: (json['annual_impact'] as num).toDouble(),
      difficulty: json['difficulty'] as String,
      currentSpending: (json['current_spending'] as num).toDouble(),
      newSpending: (json['new_spending'] as num).toDouble(),
      reason: json['reason'] as String?,
    );
  }
}

class WarningModel extends Warning {
  const WarningModel({
    required super.type,
    required super.message,
    required super.severity,
    super.metric,
    super.recommendation,
  });

  factory WarningModel.fromJson(Map<String, dynamic> json) {
    return WarningModel(
      type: json['type'] as String,
      message: json['message'] as String,
      severity: json['severity'] as String,
      metric: json['metric'] as String?,
      recommendation: json['recommendation'] as String?,
    );
  }
}

class ScenarioInsightModel extends ScenarioInsight {
  const ScenarioInsightModel({
    required super.headline,
    required super.confidence,
    required super.confidenceReason,
    required super.quickWins,
    required super.warnings,
    required super.timeline,
    required super.visualSuggestion,
    required super.annualImpact,
    required super.annualImpactValue,
    required super.achievabilityScore,
    required super.totalCategoriesAffected,
  });

  factory ScenarioInsightModel.fromJson(Map<String, dynamic> json) {
    return ScenarioInsightModel(
      headline: json['headline'] as String,
      confidence: json['confidence'] as String,
      confidenceReason: json['confidence_reason'] as String,
      quickWins: (json['quick_wins'] as List<dynamic>?)
              ?.map((e) => QuickWinModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => WarningModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeline: json['timeline'] as String,
      visualSuggestion: json['visual_suggestion'] as String? ?? 'category_breakdown_bar_chart',
      annualImpact: json['annual_impact'] as String,
      annualImpactValue: (json['annual_impact_value'] as num).toDouble(),
      achievabilityScore: json['achievability_score'] as int,
      totalCategoriesAffected: json['total_categories_affected'] as int,
    );
  }
}






