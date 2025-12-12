import 'package:equatable/equatable.dart';
import 'category_analysis.dart';

class SimulationResponse extends Equatable {
  final String scenarioType;
  final double targetPercent;
  final double achievablePercent;
  final double baselineMonthly;
  final double projectedMonthly;
  final double totalChange;
  final double annualImpact;
  final String feasibility; // "highly_achievable", "achievable", "challenging", "unrealistic"
  final Map<String, CategoryAnalysis> categoryBreakdown;
  final List<Map<String, dynamic>> recommendations;
  final List<String>? targetedCategories;

  const SimulationResponse({
    required this.scenarioType,
    required this.targetPercent,
    required this.achievablePercent,
    required this.baselineMonthly,
    required this.projectedMonthly,
    required this.totalChange,
    required this.annualImpact,
    required this.feasibility,
    required this.categoryBreakdown,
    required this.recommendations,
    this.targetedCategories,
  });

  @override
  List<Object?> get props => [
        scenarioType,
        targetPercent,
        achievablePercent,
        baselineMonthly,
        projectedMonthly,
        totalChange,
        annualImpact,
        feasibility,
        categoryBreakdown,
        recommendations,
        targetedCategories,
      ];
}





