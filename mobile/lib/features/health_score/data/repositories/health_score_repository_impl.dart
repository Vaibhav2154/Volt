import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/financial_health_score.dart';
import '../../domain/repositories/health_score_repository.dart';
import '../datasources/health_score_remote_data_source.dart';

class HealthScoreRepositoryImpl implements HealthScoreRepository {
  final HealthScoreRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HealthScoreRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, FinancialHealthScore>> getHealthScore({
    required String token,
    required int userId,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final score = await remoteDataSource.getHealthScore(
        token: token,
        userId: userId,
      );
      return Right(score);
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

