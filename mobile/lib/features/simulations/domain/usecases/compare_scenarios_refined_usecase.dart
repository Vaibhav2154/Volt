import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/refined_comparison_response.dart';
import '../repositories/simulation_repository.dart';

class CompareScenariosRefinedParams {
  final String token;
  final int userId;
  final String scenarioType;
  final int timePeriodDays;
  final int numScenarios;

  CompareScenariosRefinedParams({
    required this.token,
    required this.userId,
    required this.scenarioType,
    this.timePeriodDays = 30,
    this.numScenarios = 3,
  });
}

class CompareScenariosRefinedUseCase
    implements UseCase<RefinedComparisonResponse, CompareScenariosRefinedParams> {
  final SimulationRepository repository;

  CompareScenariosRefinedUseCase(this.repository);

  @override
  Future<Either<Failure, RefinedComparisonResponse>> call(
      CompareScenariosRefinedParams params) async {
    return await repository.compareScenariosRefined(
      token: params.token,
      userId: params.userId,
      scenarioType: params.scenarioType,
      timePeriodDays: params.timePeriodDays,
      numScenarios: params.numScenarios,
    );
  }
}

