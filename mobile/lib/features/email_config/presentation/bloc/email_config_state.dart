import 'package:equatable/equatable.dart';
import '../../domain/entities/email_app_password_response.dart';
import '../../domain/entities/email_parsing_status.dart';

abstract class EmailConfigState extends Equatable {
  const EmailConfigState();

  @override
  List<Object?> get props => [];
}

class EmailConfigInitial extends EmailConfigState {}

class EmailConfigLoading extends EmailConfigState {}

class EmailParsingStatusLoaded extends EmailConfigState {
  final EmailParsingStatus status;

  const EmailParsingStatusLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class EmailAppPasswordSetupSuccess extends EmailConfigState {
  final EmailAppPasswordResponse response;

  const EmailAppPasswordSetupSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class EmailParsingDisabledSuccess extends EmailConfigState {
  final EmailAppPasswordResponse response;

  const EmailParsingDisabledSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class EmailConfigError extends EmailConfigState {
  final String message;

  const EmailConfigError(this.message);

  @override
  List<Object?> get props => [message];
}





