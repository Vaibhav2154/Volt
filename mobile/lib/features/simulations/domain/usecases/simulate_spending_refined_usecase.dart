import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/refined_simulation_response.dart';
import '../repositories/simulation_repository.dart';

class SimulateSpendingRefinedParams {
  final String token;
  final int userId;
  final String scenarioType;
  final double targetPercent;
  final int timePeriodDays;
  final List<String>? targetCategories;

  SimulateSpendingRefinedParams({
    required this.token,
    required this.userId,
    required this.scenarioType,
    required this.targetPercent,
    this.timePeriodDays = 30,
    this.targetCategories,
  });
}

class SimulateSpendingRefinedUseCase
    implements UseCase<RefinedSimulationResponse, SimulateSpendingRefinedParams> {
  final SimulationRepository repository;

  SimulateSpendingRefinedUseCase(this.repository);

  @override
  Future<Either<Failure, RefinedSimulationResponse>> call(
      SimulateSpendingRefinedParams params) async {
    return await repository.simulateSpendingRefined(
      token: params.token,
      userId: params.userId,
      scenarioType: params.scenarioType,
      targetPercent: params.targetPercent,
      timePeriodDays: params.timePeriodDays,
      targetCategories: params.targetCategories,
    );
  }
}

