import '../../domain/entities/refined_comparison_response.dart';
import 'scenario_comparison_model.dart';

class RefinedComparisonResponseModel extends RefinedComparisonResponse {
  const RefinedComparisonResponseModel({
    required super.comparison,
    required super.refinedInsight,
  });

  factory RefinedComparisonResponseModel.fromJson(Map<String, dynamic> json) {
    return RefinedComparisonResponseModel(
      comparison: ScenarioComparisonResponseModel.fromJson(
        json['comparison'] as Map<String, dynamic>,
      ),
      refinedInsight: json['refined_insight'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    // Note: ScenarioComparisonResponseModel doesn't have toJson implemented
    // This is fine as we primarily use fromJson for API responses
    return {
      'comparison': comparison,
      'refined_insight': refinedInsight,
    };
  }
}

