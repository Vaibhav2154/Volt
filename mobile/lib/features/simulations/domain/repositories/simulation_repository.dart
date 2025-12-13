import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/projection_response.dart';
import '../entities/reallocation_response.dart';
import '../entities/refined_comparison_response.dart';
import '../entities/refined_simulation_response.dart';
import '../entities/scenario_comparison.dart';
import '../entities/scenario_insight.dart';
import '../entities/simulation_response.dart';

abstract class SimulationRepository {
  Future<Either<Failure, SimulationResponse>> simulateSpending({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  });

  Future<Either<Failure, ScenarioInsight>> simulateSpendingEnhanced({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  });

  Future<Either<Failure, ScenarioComparisonResponse>> compareScenarios({
    required String token,
    required int userId,
    required String scenarioType,
    int timePeriodDays = 30,
    int numScenarios = 3,
  });

  Future<Either<Failure, ReallocationResponse>> simulateReallocation({
    required String token,
    required int userId,
    required Map<String, double> reallocations,
    int timePeriodDays = 30,
  });

  Future<Either<Failure, ProjectionResponse>> projectFutureSpending({
    required String token,
    required int userId,
    required int projectionMonths,
    int timePeriodDays = 30,
    String? scenarioId,
    Map<String, double>? behavioralChanges,
  });

  Future<Either<Failure, RefinedSimulationResponse>> simulateSpendingRefined({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  });

  Future<Either<Failure, RefinedComparisonResponse>> compareScenariosRefined({
    required String token,
    required int userId,
    required String scenarioType,
    int timePeriodDays = 30,
    int numScenarios = 3,
  });
}





