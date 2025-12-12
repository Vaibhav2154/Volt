import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../domain/entities/gamification_feed.dart';
import '../../domain/entities/gamification_profile.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/gamification_remote_data_source.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final AuthLocalDataSource authLocalDataSource;

  GamificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.authLocalDataSource,
  });

  Future<String> _getToken() async {
    final token = await authLocalDataSource.getToken();
    if (token == null) {
      throw const UnauthorizedException('Not authenticated');
    }
    return token;
  }

  @override
  Future<Either<Failure, GamificationProfile>> getProfile() async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final token = await _getToken();
      final profile = await remoteDataSource.getProfile(token: token);
      return Right(profile);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, GamificationFeed>> getFeed({int limit = 20}) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final token = await _getToken();
      final feed = await remoteDataSource.getFeed(token: token, limit: limit);
      return Right(feed);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }
}

