import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/scenario_comparison.dart';
import '../repositories/simulation_repository.dart';

class CompareScenariosParams {
  final String token;
  final int userId;
  final String scenarioType;
  final int timePeriodDays;
  final int numScenarios;

  CompareScenariosParams({
    required this.token,
    required this.userId,
    required this.scenarioType,
    this.timePeriodDays = 30,
    this.numScenarios = 3,
  });
}

class CompareScenariosUseCase
    implements UseCase<ScenarioComparisonResponse, CompareScenariosParams> {
  final SimulationRepository repository;

  CompareScenariosUseCase(this.repository);

  @override
  Future<Either<Failure, ScenarioComparisonResponse>> call(
      CompareScenariosParams params) async {
    return await repository.compareScenarios(
      token: params.token,
      userId: params.userId,
      scenarioType: params.scenarioType,
      timePeriodDays: params.timePeriodDays,
      numScenarios: params.numScenarios,
    );
  }
}







