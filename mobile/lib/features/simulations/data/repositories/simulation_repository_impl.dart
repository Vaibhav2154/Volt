import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/projection_response.dart';
import '../../domain/entities/reallocation_response.dart';
import '../../domain/entities/scenario_comparison.dart';
import '../../domain/entities/scenario_insight.dart';
import '../../domain/entities/simulation_response.dart';
import '../../domain/repositories/simulation_repository.dart';
import '../datasources/simulation_remote_data_source.dart';

class SimulationRepositoryImpl implements SimulationRepository {
  final SimulationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SimulationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, SimulationResponse>> simulateSpending({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.simulateSpending(
        token: token,
        userId: userId,
        scenarioType: scenarioType,
        targetPercent: targetPercent,
        timePeriodDays: timePeriodDays,
        targetCategories: targetCategories,
      );
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, ScenarioInsight>> simulateSpendingEnhanced({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.simulateSpendingEnhanced(
        token: token,
        userId: userId,
        scenarioType: scenarioType,
        targetPercent: targetPercent,
        timePeriodDays: timePeriodDays,
        targetCategories: targetCategories,
      );
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, ScenarioComparisonResponse>> compareScenarios({
    required String token,
    required int userId,
    required String scenarioType,
    int timePeriodDays = 30,
    int numScenarios = 3,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.compareScenarios(
        token: token,
        userId: userId,
        scenarioType: scenarioType,
        timePeriodDays: timePeriodDays,
        numScenarios: numScenarios,
      );
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, ReallocationResponse>> simulateReallocation({
    required String token,
    required int userId,
    required Map<String, double> reallocations,
    int timePeriodDays = 30,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.simulateReallocation(
        token: token,
        userId: userId,
        reallocations: reallocations,
        timePeriodDays: timePeriodDays,
      );
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, ProjectionResponse>> projectFutureSpending({
    required String token,
    required int userId,
    required int projectionMonths,
    int timePeriodDays = 30,
    String? scenarioId,
    Map<String, double>? behavioralChanges,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final result = await remoteDataSource.projectFutureSpending(
        token: token,
        userId: userId,
        projectionMonths: projectionMonths,
        timePeriodDays: timePeriodDays,
        scenarioId: scenarioId,
        behavioralChanges: behavioralChanges,
      );
      return Right(result);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }
}





