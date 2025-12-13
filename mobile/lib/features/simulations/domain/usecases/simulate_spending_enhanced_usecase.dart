import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/scenario_insight.dart';
import '../repositories/simulation_repository.dart';

class SimulateSpendingEnhancedParams {
  final String token;
  final int userId;
  final String scenarioType;
  final double targetPercent;
  final int timePeriodDays;
  final List<String>? targetCategories;

  SimulateSpendingEnhancedParams({
    required this.token,
    required this.userId,
    required this.scenarioType,
    required this.targetPercent,
    this.timePeriodDays = 30,
    this.targetCategories,
  });
}

class SimulateSpendingEnhancedUseCase
    implements UseCase<ScenarioInsight, SimulateSpendingEnhancedParams> {
  final SimulationRepository repository;

  SimulateSpendingEnhancedUseCase(this.repository);

  @override
  Future<Either<Failure, ScenarioInsight>> call(
      SimulateSpendingEnhancedParams params) async {
    return await repository.simulateSpendingEnhanced(
      token: params.token,
      userId: params.userId,
      scenarioType: params.scenarioType,
      targetPercent: params.targetPercent,
      timePeriodDays: params.timePeriodDays,
      targetCategories: params.targetCategories,
    );
  }
}






