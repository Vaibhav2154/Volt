import '../../domain/entities/cash_flow_scenario.dart';

class CashFlowScenarioModel extends CashFlowScenario {
  const CashFlowScenarioModel({
    required super.best,
    required super.likely,
    required super.worst,
  });

  factory CashFlowScenarioModel.fromJson(Map<String, dynamic> json) {
    return CashFlowScenarioModel(
      best: (json['best'] as num).toDouble(),
      likely: (json['likely'] as num).toDouble(),
      worst: (json['worst'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'best': best,
      'likely': likely,
      'worst': worst,
    };
  }
}






