import '../../domain/entities/reallocation_response.dart';

class CategoryReallocationModel extends CategoryReallocation {
  const CategoryReallocationModel({
    required super.category,
    required super.currentMonthly,
    required super.changeAmount,
    required super.newMonthly,
    required super.changePercent,
    required super.feasibility,
    required super.impactNote,
  });

  factory CategoryReallocationModel.fromJson(Map<String, dynamic> json) {
    // Handle both string and num types for decimal fields
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      return 0.0;
    }

    return CategoryReallocationModel(
      category: json['category'] as String,
      currentMonthly: parseAmount(json['current_monthly']),
      changeAmount: parseAmount(json['change_amount']),
      newMonthly: parseAmount(json['new_monthly']),
      changePercent: (json['change_percent'] as num).toDouble(),
      feasibility: json['feasibility'] as String,
      impactNote: json['impact_note'] as String,
    );
  }
}

class ReallocationResponseModel extends ReallocationResponse {
  const ReallocationResponseModel({
    required super.baselineMonthly,
    required super.projectedMonthly,
    required super.isBalanced,
    required super.reallocations,
    required super.feasibilityAssessment,
    required super.warnings,
    required super.recommendations,
    required super.visualData,
  });

  factory ReallocationResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle both string and num types for decimal fields
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      return 0.0;
    }

    return ReallocationResponseModel(
      baselineMonthly: parseAmount(json['baseline_monthly']),
      projectedMonthly: parseAmount(json['projected_monthly']),
      isBalanced: json['is_balanced'] as bool,
      reallocations: (json['reallocations'] as List<dynamic>)
          .map((e) => CategoryReallocationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      feasibilityAssessment: json['feasibility_assessment'] as String,
      warnings: (json['warnings'] as List<dynamic>).map((e) => e as String).toList(),
      recommendations: (json['recommendations'] as List<dynamic>).map((e) => e as String).toList(),
      visualData: json['visual_data'] as Map<String, dynamic>,
    );
  }
}

