import '../../domain/entities/projection_response.dart';

class MonthlyProjectionModel extends MonthlyProjection {
  const MonthlyProjectionModel({
    required super.month,
    required super.monthLabel,
    required super.projectedSpending,
    required super.categoryBreakdown,
    required super.cumulativeChange,
    required super.confidence,
  });

  factory MonthlyProjectionModel.fromJson(Map<String, dynamic> json) {
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
    final categoryBreakdownMap = <String, double>{};
    if (json['category_breakdown'] != null) {
      final breakdown = json['category_breakdown'] as Map<String, dynamic>;
      breakdown.forEach((key, value) {
        categoryBreakdownMap[key] = parseAmount(value);
      });
    }

    return MonthlyProjectionModel(
      month: json['month'] as int,
      monthLabel: json['month_label'] as String,
      projectedSpending: parseAmount(json['projected_spending']),
      categoryBreakdown: categoryBreakdownMap,
      cumulativeChange: parseAmount(json['cumulative_change']),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class ProjectionResponseModel extends ProjectionResponse {
  const ProjectionResponseModel({
    required super.baselineMonthly,
    required super.projectionMonths,
    required super.monthlyProjections,
    required super.totalProjected,
    required super.totalBaseline,
    required super.cumulativeChange,
    required super.annualImpact,
    required super.trendAnalysis,
    required super.confidenceLevel,
    required super.keyInsights,
    required super.projectionChart,
  });

  factory ProjectionResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle both string and num types for decimal fields
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      return 0.0;
    }

    return ProjectionResponseModel(
      baselineMonthly: parseAmount(json['baseline_monthly']),
      projectionMonths: json['projection_months'] as int,
      monthlyProjections: (json['monthly_projections'] as List<dynamic>)
          .map((e) => MonthlyProjectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalProjected: parseAmount(json['total_projected']),
      totalBaseline: parseAmount(json['total_baseline']),
      cumulativeChange: parseAmount(json['cumulative_change']),
      annualImpact: parseAmount(json['annual_impact']),
      trendAnalysis: json['trend_analysis'] as String,
      confidenceLevel: json['confidence_level'] as String,
      keyInsights: (json['key_insights'] as List<dynamic>).map((e) => e as String).toList(),
      projectionChart: json['projection_chart'] as Map<String, dynamic>,
    );
  }
}

