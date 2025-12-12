import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reallocation_response.dart';
import '../repositories/simulation_repository.dart';

class SimulateReallocationParams {
  final String token;
  final int userId;
  final Map<String, double> reallocations;
  final int timePeriodDays;

  SimulateReallocationParams({
    required this.token,
    required this.userId,
    required this.reallocations,
    this.timePeriodDays = 30,
  });
}

class SimulateReallocationUseCase
    implements UseCase<ReallocationResponse, SimulateReallocationParams> {
  final SimulationRepository repository;

  SimulateReallocationUseCase(this.repository);

  @override
  Future<Either<Failure, ReallocationResponse>> call(
      SimulateReallocationParams params) async {
    return await repository.simulateReallocation(
      token: params.token,
      userId: params.userId,
      reallocations: params.reallocations,
      timePeriodDays: params.timePeriodDays,
    );
  }
}





