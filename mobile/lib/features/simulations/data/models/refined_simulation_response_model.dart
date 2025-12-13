import '../../domain/entities/refined_simulation_response.dart';
import 'simulation_response_model.dart';

class RefinedSimulationResponseModel extends RefinedSimulationResponse {
  const RefinedSimulationResponseModel({
    required super.simulation,
    required super.refinedInsight,
  });

  factory RefinedSimulationResponseModel.fromJson(Map<String, dynamic> json) {
    return RefinedSimulationResponseModel(
      simulation: SimulationResponseModel.fromJson(
        json['simulation'] as Map<String, dynamic>,
      ),
      refinedInsight: json['refined_insight'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'simulation': (simulation as SimulationResponseModel).toJson(),
      'refined_insight': refinedInsight,
    };
  }
}

