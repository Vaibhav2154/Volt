import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/projection_response.dart';
import '../repositories/simulation_repository.dart';

class ProjectFutureSpendingParams {
  final String token;
  final int userId;
  final int projectionMonths;
  final int timePeriodDays;
  final String? scenarioId;
  final Map<String, double>? behavioralChanges;

  ProjectFutureSpendingParams({
    required this.token,
    required this.userId,
    required this.projectionMonths,
    this.timePeriodDays = 30,
    this.scenarioId,
    this.behavioralChanges,
  });
}

class ProjectFutureSpendingUseCase
    implements UseCase<ProjectionResponse, ProjectFutureSpendingParams> {
  final SimulationRepository repository;

  ProjectFutureSpendingUseCase(this.repository);

  @override
  Future<Either<Failure, ProjectionResponse>> call(
      ProjectFutureSpendingParams params) async {
    return await repository.projectFutureSpending(
      token: params.token,
      userId: params.userId,
      projectionMonths: params.projectionMonths,
      timePeriodDays: params.timePeriodDays,
      scenarioId: params.scenarioId,
      behavioralChanges: params.behavioralChanges,
    );
  }
}






