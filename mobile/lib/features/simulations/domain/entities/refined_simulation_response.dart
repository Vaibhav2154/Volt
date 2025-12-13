import 'package:equatable/equatable.dart';
import 'simulation_response.dart';

class RefinedSimulationResponse extends Equatable {
  final SimulationResponse simulation;
  final String refinedInsight; // Markdown string

  const RefinedSimulationResponse({
    required this.simulation,
    required this.refinedInsight,
  });

  @override
  List<Object?> get props => [simulation, refinedInsight];
}

