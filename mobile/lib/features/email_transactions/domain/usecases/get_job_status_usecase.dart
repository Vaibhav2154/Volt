import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job_status.dart';
import '../repositories/email_transactions_repository.dart';

class GetJobStatusUseCase
    implements UseCase<JobStatus, GetJobStatusParams> {
  final EmailTransactionsRepository repository;

  GetJobStatusUseCase(this.repository);

  @override
  Future<Either<Failure, JobStatus>> call(GetJobStatusParams params) async {
    return await repository.getJobStatus(
      jobId: params.jobId,
      token: params.token,
    );
  }
}

class GetJobStatusParams {
  final String jobId;
  final String token;

  GetJobStatusParams({
    required this.jobId,
    required this.token,
  });
}





