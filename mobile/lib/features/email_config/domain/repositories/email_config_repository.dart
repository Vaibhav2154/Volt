import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/email_app_password_response.dart';
import '../entities/email_parsing_status.dart';

abstract class EmailConfigRepository {
  Future<Either<Failure, EmailAppPasswordResponse>> setupAppPassword({
    required String appPassword,
    required bool consent,
    required String token,
  });

  Future<Either<Failure, EmailParsingStatus>> getEmailParsingStatus({
    required String token,
  });

  Future<Either<Failure, EmailAppPasswordResponse>> disableEmailParsing({
    required bool confirm,
    required String token,
  });

  Future<Either<Failure, EmailAppPasswordResponse>> updateAppPassword({
    required String appPassword,
    required bool consent,
    required String token,
  });
}





