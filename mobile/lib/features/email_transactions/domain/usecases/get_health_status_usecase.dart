import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/email_health_status.dart';
import '../repositories/email_transactions_repository.dart';

class GetHealthStatusUseCase implements UseCase<EmailHealthStatus, String> {
  final EmailTransactionsRepository repository;

  GetHealthStatusUseCase(this.repository);

  @override
  Future<Either<Failure, EmailHealthStatus>> call(String token) async {
    return await repository.getHealthStatus(token: token);
  }
}






