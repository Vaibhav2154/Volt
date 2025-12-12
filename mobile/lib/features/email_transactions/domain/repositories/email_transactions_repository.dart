import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/email_health_status.dart';
import '../entities/job_stats.dart';
import '../entities/job_status.dart';
import '../entities/manual_email_job_response.dart';
import '../../../transactions/domain/entities/transaction.dart' as transaction_entity;

abstract class EmailTransactionsRepository {
  Future<Either<Failure, JobStats>> getQueueStats({
    required String token,
  });

  Future<Either<Failure, JobStatus>> getJobStatus({
    required String jobId,
    required String token,
  });

  Future<Either<Failure, ManualEmailJobResponse>> enqueueManualEmail({
    required String sender,
    required String subject,
    required String body,
    required String token,
  });

  Future<Either<Failure, List<transaction_entity.TransactionEntity>>> getRecentTransactions({
    required String token,
    int limit = 20,
  });

  Future<Either<Failure, List<transaction_entity.TransactionEntity>>> getTransactionsByBank({
    required String bankName,
    required String token,
    int limit = 20,
  });

  Future<Either<Failure, EmailHealthStatus>> getHealthStatus({
    required String token,
  });
}

