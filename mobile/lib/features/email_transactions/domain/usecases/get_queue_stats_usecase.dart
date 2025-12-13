import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/job_stats.dart';
import '../repositories/email_transactions_repository.dart';

class GetQueueStatsUseCase implements UseCase<JobStats, String> {
  final EmailTransactionsRepository repository;

  GetQueueStatsUseCase(this.repository);

  @override
  Future<Either<Failure, JobStats>> call(String token) async {
    return await repository.getQueueStats(token: token);
  }
}







