import '../../domain/entities/category_analysis.dart';

class CategoryAnalysisModel extends CategoryAnalysis {
  const CategoryAnalysisModel({
    required super.currentMonthly,
    required super.maxReductionPct,
    required super.achievableReductionPct,
    required super.monthlySavings,
    required super.confidence,
    required super.difficulty,
  });

  factory CategoryAnalysisModel.fromJson(Map<String, dynamic> json) {
    // Handle both string and num types for decimal fields
    double parseAmount(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      }
      return 0.0;
    }

    return CategoryAnalysisModel(
      currentMonthly: parseAmount(json['current_monthly']),
      maxReductionPct: (json['max_reduction_pct'] as num).toDouble(),
      achievableReductionPct: (json['achievable_reduction_pct'] as num).toDouble(),
      monthlySavings: parseAmount(json['monthly_savings']),
      confidence: (json['confidence'] as num).toDouble(),
      difficulty: json['difficulty'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_monthly': currentMonthly,
      'max_reduction_pct': maxReductionPct,
      'achievable_reduction_pct': achievableReductionPct,
      'monthly_savings': monthlySavings,
      'confidence': confidence,
      'difficulty': difficulty,
    };
  }
}

