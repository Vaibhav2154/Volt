import 'package:equatable/equatable.dart';

class ScenarioSummary extends Equatable {
  final String scenarioId;
  final String name;
  final String description;
  final String scenarioType;
  final double targetPercent;
  final double achievablePercent;
  final double baselineMonthly;
  final double projectedMonthly;
  final double totalChange;
  final double annualImpact;
  final String feasibility;
  final double difficultyScore;
  final List<String> topCategories;
  final String keyInsight;

  const ScenarioSummary({
    required this.scenarioId,
    required this.name,
    required this.description,
    required this.scenarioType,
    required this.targetPercent,
    required this.achievablePercent,
    required this.baselineMonthly,
    required this.projectedMonthly,
    required this.totalChange,
    required this.annualImpact,
    required this.feasibility,
    required this.difficultyScore,
    required this.topCategories,
    required this.keyInsight,
  });

  @override
  List<Object?> get props => [
        scenarioId,
        name,
        description,
        scenarioType,
        targetPercent,
        achievablePercent,
        baselineMonthly,
        projectedMonthly,
        totalChange,
        annualImpact,
        feasibility,
        difficultyScore,
        topCategories,
        keyInsight,
      ];
}

class ScenarioComparisonResponse extends Equatable {
  final String scenarioType;
  final double baselineMonthly;
  final int timePeriodDays;
  final List<ScenarioSummary> scenarios;
  final String recommendedScenarioId;
  final Map<String, dynamic> comparisonChart;
  final List<String> insights;

  const ScenarioComparisonResponse({
    required this.scenarioType,
    required this.baselineMonthly,
    required this.timePeriodDays,
    required this.scenarios,
    required this.recommendedScenarioId,
    required this.comparisonChart,
    required this.insights,
  });

  @override
  List<Object?> get props => [
        scenarioType,
        baselineMonthly,
        timePeriodDays,
        scenarios,
        recommendedScenarioId,
        comparisonChart,
        insights,
      ];
}






