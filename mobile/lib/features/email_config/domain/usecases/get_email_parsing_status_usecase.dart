import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/email_parsing_status.dart';
import '../repositories/email_config_repository.dart';

class GetEmailParsingStatusUseCase
    implements UseCase<EmailParsingStatus, String> {
  final EmailConfigRepository repository;

  GetEmailParsingStatusUseCase(this.repository);

  @override
  Future<Either<Failure, EmailParsingStatus>> call(String token) async {
    return await repository.getEmailParsingStatus(token: token);
  }
}

