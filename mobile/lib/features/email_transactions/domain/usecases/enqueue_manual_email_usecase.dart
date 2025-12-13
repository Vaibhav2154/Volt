import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/manual_email_job_response.dart';
import '../repositories/email_transactions_repository.dart';

class EnqueueManualEmailUseCase
    implements UseCase<ManualEmailJobResponse, EnqueueManualEmailParams> {
  final EmailTransactionsRepository repository;

  EnqueueManualEmailUseCase(this.repository);

  @override
  Future<Either<Failure, ManualEmailJobResponse>> call(
      EnqueueManualEmailParams params) async {
    return await repository.enqueueManualEmail(
      sender: params.sender,
      subject: params.subject,
      body: params.body,
      token: params.token,
    );
  }
}

class EnqueueManualEmailParams {
  final String sender;
  final String subject;
  final String body;
  final String token;

  EnqueueManualEmailParams({
    required this.sender,
    required this.subject,
    required this.body,
    required this.token,
  });
}






