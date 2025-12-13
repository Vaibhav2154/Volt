import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/email_app_password_response.dart';
import '../repositories/email_config_repository.dart';

class SetupAppPasswordUseCase
    implements UseCase<EmailAppPasswordResponse, SetupAppPasswordParams> {
  final EmailConfigRepository repository;

  SetupAppPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, EmailAppPasswordResponse>> call(
      SetupAppPasswordParams params) async {
    return await repository.setupAppPassword(
      appPassword: params.appPassword,
      consent: params.consent,
      token: params.token,
    );
  }
}

class SetupAppPasswordParams {
  final String appPassword;
  final bool consent;
  final String token;

  SetupAppPasswordParams({
    required this.appPassword,
    required this.consent,
    required this.token,
  });
}






