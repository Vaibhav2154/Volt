import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/email_app_password_response.dart';
import '../repositories/email_config_repository.dart';

class UpdateAppPasswordUseCase
    implements UseCase<EmailAppPasswordResponse, UpdateAppPasswordParams> {
  final EmailConfigRepository repository;

  UpdateAppPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, EmailAppPasswordResponse>> call(
      UpdateAppPasswordParams params) async {
    return await repository.updateAppPassword(
      appPassword: params.appPassword,
      consent: params.consent,
      token: params.token,
    );
  }
}

class UpdateAppPasswordParams {
  final String appPassword;
  final bool consent;
  final String token;

  UpdateAppPasswordParams({
    required this.appPassword,
    required this.consent,
    required this.token,
  });
}

