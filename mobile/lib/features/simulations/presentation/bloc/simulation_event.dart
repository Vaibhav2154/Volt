import 'package:equatable/equatable.dart';

abstract class SimulationEvent extends Equatable {
  const SimulationEvent();

  @override
  List<Object?> get props => [];
}

class SimulateSpendingEvent extends SimulationEvent {
  final String token;
  final int userId;
  final String scenarioType;
  final double targetPercent;
  final int timePeriodDays;
  final List<String>? targetCategories;

  const SimulateSpendingEvent({
    required this.token,
    required this.userId,
    required this.scenarioType,
    required this.targetPercent,
    this.timePeriodDays = 30,
    this.targetCategories,
  });

  @override
  List<Object?> get props => [
        token,
        userId,
        scenarioType,
        targetPercent,
        timePeriodDays,
        targetCategories,
      ];
}

class SimulateSpendingEnhancedEvent extends SimulationEvent {
  final String token;
  final int userId;
  final String scenarioType;
  final double targetPercent;
  final int timePeriodDays;
  final List<String>? targetCategories;

  const SimulateSpendingEnhancedEvent({
    required this.token,
    required this.userId,
    required this.scenarioType,
    required this.targetPercent,
    this.timePeriodDays = 30,
    this.targetCategories,
  });

  @override
  List<Object?> get props => [
        token,
        userId,
        scenarioType,
        targetPercent,
        timePeriodDays,
        targetCategories,
      ];
}

class CompareScenariosEvent extends SimulationEvent {
  final String token;
  final int userId;
  final String scenarioType;
  final int timePeriodDays;
  final int numScenarios;

  const CompareScenariosEvent({
    required this.token,
    required this.userId,
    required this.scenarioType,
    this.timePeriodDays = 30,
    this.numScenarios = 3,
  });

  @override
  List<Object?> get props => [
        token,
        userId,
        scenarioType,
        timePeriodDays,
        numScenarios,
      ];
}

class SimulateReallocationEvent extends SimulationEvent {
  final String token;
  final int userId;
  final Map<String, double> reallocations;
  final int timePeriodDays;

  const SimulateReallocationEvent({
    required this.token,
    required this.userId,
    required this.reallocations,
    this.timePeriodDays = 30,
  });

  @override
  List<Object?> get props => [token, userId, reallocations, timePeriodDays];
}

class ProjectFutureSpendingEvent extends SimulationEvent {
  final String token;
  final int userId;
  final int projectionMonths;
  final int timePeriodDays;
  final String? scenarioId;
  final Map<String, double>? behavioralChanges;

  const ProjectFutureSpendingEvent({
    required this.token,
    required this.userId,
    required this.projectionMonths,
    this.timePeriodDays = 30,
    this.scenarioId,
    this.behavioralChanges,
  });

  @override
  List<Object?> get props => [
        token,
        userId,
        projectionMonths,
        timePeriodDays,
        scenarioId,
        behavioralChanges,
      ];
}

class SimulateSpendingRefinedEvent extends SimulationEvent {
  final String token;
  final int userId;
  final String scenarioType;
  final double targetPercent;
  final int timePeriodDays;
  final List<String>? targetCategories;

  const SimulateSpendingRefinedEvent({
    required this.token,
    required this.userId,
    required this.scenarioType,
    required this.targetPercent,
    this.timePeriodDays = 30,
    this.targetCategories,
  });

  @override
  List<Object?> get props => [
        token,
        userId,
        scenarioType,
        targetPercent,
        timePeriodDays,
        targetCategories,
      ];
}

class CompareScenariosRefinedEvent extends SimulationEvent {
  final String token;
  final int userId;
  final String scenarioType;
  final int timePeriodDays;
  final int numScenarios;

  const CompareScenariosRefinedEvent({
    required this.token,
    required this.userId,
    required this.scenarioType,
    this.timePeriodDays = 30,
    this.numScenarios = 3,
  });

  @override
  List<Object?> get props => [
        token,
        userId,
        scenarioType,
        timePeriodDays,
        numScenarios,
      ];
}





