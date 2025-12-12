import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../transactions/domain/entities/transaction.dart' as transaction_entity;
import '../../domain/entities/email_health_status.dart';
import '../../domain/entities/job_stats.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/entities/manual_email_job_response.dart';
import '../../domain/repositories/email_transactions_repository.dart';
import '../datasources/email_transactions_remote_data_source.dart';

class EmailTransactionsRepositoryImpl
    implements EmailTransactionsRepository {
  final EmailTransactionsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  EmailTransactionsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, JobStats>> getQueueStats({
    required String token,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getQueueStats(token: token);
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
  Future<Either<Failure, JobStatus>> getJobStatus({
    required String jobId,
    required String token,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getJobStatus(
        jobId: jobId,
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
  Future<Either<Failure, ManualEmailJobResponse>> enqueueManualEmail({
    required String sender,
    required String subject,
    required String body,
    required String token,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.enqueueManualEmail(
        sender: sender,
        subject: subject,
        body: body,
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
  Future<Either<Failure, List<transaction_entity.TransactionEntity>>>
      getRecentTransactions({
    required String token,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getRecentTransactions(
        token: token,
        limit: limit,
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
  Future<Either<Failure, List<transaction_entity.TransactionEntity>>>
      getTransactionsByBank({
    required String bankName,
    required String token,
    int limit = 20,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getTransactionsByBank(
        bankName: bankName,
        token: token,
        limit: limit,
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
  Future<Either<Failure, EmailHealthStatus>> getHealthStatus({
    required String token,
  }) async {
    if (!await networkInfo.isConnected()) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final response = await remoteDataSource.getHealthStatus(token: token);
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

