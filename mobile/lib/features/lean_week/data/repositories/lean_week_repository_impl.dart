import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/cash_flow_forecast.dart';
import '../../domain/entities/income_smoothing_recommendation.dart';
import '../../domain/entities/lean_week_analysis.dart';
import '../../domain/repositories/lean_week_repository.dart';
import '../datasources/lean_week_remote_data_source.dart';

class LeanWeekRepositoryImpl implements LeanWeekRepository {
  final LeanWeekRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  LeanWeekRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, LeanWeekAnalysis>> getLeanWeekAnalysis({
    required String token,
    double? currentBalance,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getLeanWeekAnalysis(
        token: token,
        currentBalance: currentBalance,
      );
      return Right(response);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, CashFlowForecast>> getCashFlowForecast({
    required String token,
    int periods = 3,
    double? currentBalance,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getCashFlowForecast(
        token: token,
        periods: periods,
        currentBalance: currentBalance,
      );
      return Right(response);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, IncomeSmoothingRecommendation>>
      getIncomeSmoothingRecommendations({
    required String token,
    double? currentBalance,
    int targetMonths = 3,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response =
          await remoteDataSource.getIncomeSmoothingRecommendations(
        token: token,
        currentBalance: currentBalance,
        targetMonths: targetMonths,
      );
      return Right(response);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }
}





