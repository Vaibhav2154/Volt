import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/email_app_password_response.dart';
import '../../domain/entities/email_parsing_status.dart';
import '../../domain/repositories/email_config_repository.dart';
import '../datasources/email_config_remote_data_source.dart';

class EmailConfigRepositoryImpl implements EmailConfigRepository {
  final EmailConfigRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  EmailConfigRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, EmailAppPasswordResponse>> setupAppPassword({
    required String appPassword,
    required bool consent,
    required String token,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.setupAppPassword(
        appPassword: appPassword,
        consent: consent,
        token: token,
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
  Future<Either<Failure, EmailParsingStatus>> getEmailParsingStatus({
    required String token,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getEmailParsingStatus(
        token: token,
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
  Future<Either<Failure, EmailAppPasswordResponse>> disableEmailParsing({
    required bool confirm,
    required String token,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.disableEmailParsing(
        confirm: confirm,
        token: token,
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
  Future<Either<Failure, EmailAppPasswordResponse>> updateAppPassword({
    required String appPassword,
    required bool consent,
    required String token,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.updateAppPassword(
        appPassword: appPassword,
        consent: consent,
        token: token,
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

