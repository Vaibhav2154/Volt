import 'package:equatable/equatable.dart';
import '../../domain/entities/projection_response.dart';
import '../../domain/entities/reallocation_response.dart';
import '../../domain/entities/scenario_comparison.dart';
import '../../domain/entities/scenario_insight.dart';
import '../../domain/entities/simulation_response.dart';

abstract class SimulationState extends Equatable {
  const SimulationState();

  @override
  List<Object?> get props => [];
}

class SimulationInitial extends SimulationState {}

class SimulationLoading extends SimulationState {}

class SimulationLoaded extends SimulationState {
  final SimulationResponse response;

  const SimulationLoaded(this.response);

  @override
  List<Object?> get props => [response];
}

class SimulationEnhancedLoaded extends SimulationState {
  final ScenarioInsight insight;

  const SimulationEnhancedLoaded(this.insight);

  @override
  List<Object?> get props => [insight];
}

class ScenariosCompared extends SimulationState {
  final ScenarioComparisonResponse comparison;

  const ScenariosCompared(this.comparison);

  @override
  List<Object?> get props => [comparison];
}

class ReallocationSimulated extends SimulationState {
  final ReallocationResponse response;

  const ReallocationSimulated(this.response);

  @override
  List<Object?> get props => [response];
}

class FutureSpendingProjected extends SimulationState {
  final ProjectionResponse response;

  const FutureSpendingProjected(this.response);

  @override
  List<Object?> get props => [response];
}

class SimulationError extends SimulationState {
  final String message;

  const SimulationError(this.message);

  @override
  List<Object?> get props => [message];
}

