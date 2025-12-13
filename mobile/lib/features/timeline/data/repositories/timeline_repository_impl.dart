import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/animated_timeline.dart';
import '../../domain/repositories/timeline_repository.dart';
import '../datasources/timeline_remote_data_source.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  final TimelineRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TimelineRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AnimatedTimeline>> getAnimatedTimeline({
    required String token,
    required int userId,
    String timelineType = 'monthly',
    int periods = 12,
    bool includeForecast = true,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final timeline = await remoteDataSource.getAnimatedTimeline(
        token: token,
        userId: userId,
        timelineType: timelineType,
        periods: periods,
        includeForecast: includeForecast,
      );
      return Right(timeline);
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

