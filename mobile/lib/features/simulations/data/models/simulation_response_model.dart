import '../../domain/entities/category_analysis.dart';
import '../../domain/entities/simulation_response.dart';
import 'category_analysis_model.dart';

class SimulationResponseModel extends SimulationResponse {
  const SimulationResponseModel({
    required super.scenarioType,
    required super.targetPercent,
    required super.achievablePercent,
    required super.baselineMonthly,
    required super.projectedMonthly,
    required super.totalChange,
    required super.annualImpact,
    required super.feasibility,
    required super.categoryBreakdown,
    required super.recommendations,
    super.targetedCategories,
  });

  factory SimulationResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle both string and num types for decimal fields
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      return 0.0;
    }

    // Parse category breakdown
    final categoryBreakdownMap = <String, CategoryAnalysis>{};
    if (json['category_breakdown'] != null) {
      final breakdown = json['category_breakdown'] as Map<String, dynamic>;
      breakdown.forEach((key, value) {
        categoryBreakdownMap[key] =
            CategoryAnalysisModel.fromJson(value as Map<String, dynamic>);
      });
    }

    return SimulationResponseModel(
      scenarioType: json['scenario_type'] as String,
      targetPercent: (json['target_percent'] as num).toDouble(),
      achievablePercent: (json['achievable_percent'] as num).toDouble(),
      baselineMonthly: parseAmount(json['baseline_monthly']),
      projectedMonthly: parseAmount(json['projected_monthly']),
      totalChange: parseAmount(json['total_change']),
      annualImpact: parseAmount(json['annual_impact']),
      feasibility: json['feasibility'] as String,
      categoryBreakdown: categoryBreakdownMap,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      targetedCategories: json['targeted_categories'] != null
          ? (json['targeted_categories'] as List<dynamic>).map((e) => e as String).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenario_type': scenarioType,
      'target_percent': targetPercent,
      'achievable_percent': achievablePercent,
      'baseline_monthly': baselineMonthly,
      'projected_monthly': projectedMonthly,
      'total_change': totalChange,
      'annual_impact': annualImpact,
      'feasibility': feasibility,
      'category_breakdown': categoryBreakdown.map(
        (key, value) => MapEntry(key, (value as CategoryAnalysisModel).toJson()),
      ),
      'recommendations': recommendations,
      if (targetedCategories != null) 'targeted_categories': targetedCategories,
    };
  }
}

