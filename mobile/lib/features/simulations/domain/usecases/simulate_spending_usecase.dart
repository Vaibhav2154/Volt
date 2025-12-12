import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/simulation_response.dart';
import '../repositories/simulation_repository.dart';

class SimulateSpendingParams {
  final String token;
  final int userId;
  final String scenarioType;
  final double targetPercent;
  final int timePeriodDays;
  final List<String>? targetCategories;

  SimulateSpendingParams({
    required this.token,
    required this.userId,
    required this.scenarioType,
    required this.targetPercent,
    this.timePeriodDays = 30,
    this.targetCategories,
  });
}

class SimulateSpendingUseCase
    implements UseCase<SimulationResponse, SimulateSpendingParams> {
  final SimulationRepository repository;

  SimulateSpendingUseCase(this.repository);

  @override
  Future<Either<Failure, SimulationResponse>> call(
      SimulateSpendingParams params) async {
    return await repository.simulateSpending(
      token: params.token,
      userId: params.userId,
      scenarioType: params.scenarioType,
      targetPercent: params.targetPercent,
      timePeriodDays: params.timePeriodDays,
      targetCategories: params.targetCategories,
    );
  }
}





