import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/email_app_password_response.dart';
import '../repositories/email_config_repository.dart';

class DisableEmailParsingUseCase
    implements UseCase<EmailAppPasswordResponse, DisableEmailParsingParams> {
  final EmailConfigRepository repository;

  DisableEmailParsingUseCase(this.repository);

  @override
  Future<Either<Failure, EmailAppPasswordResponse>> call(
      DisableEmailParsingParams params) async {
    return await repository.disableEmailParsing(
      confirm: params.confirm,
      token: params.token,
    );
  }
}

class DisableEmailParsingParams {
  final bool confirm;
  final String token;

  DisableEmailParsingParams({
    required this.confirm,
    required this.token,
  });
}





