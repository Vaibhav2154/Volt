import 'package:equatable/equatable.dart';

abstract class EmailConfigEvent extends Equatable {
  const EmailConfigEvent();

  @override
  List<Object?> get props => [];
}

class SetupAppPasswordEvent extends EmailConfigEvent {
  final String appPassword;
  final bool consent;
  final String token;

  const SetupAppPasswordEvent({
    required this.appPassword,
    required this.consent,
    required this.token,
  });

  @override
  List<Object?> get props => [appPassword, consent, token];
}

class GetEmailParsingStatusEvent extends EmailConfigEvent {
  final String token;

  const GetEmailParsingStatusEvent({required this.token});

  @override
  List<Object?> get props => [token];
}

class DisableEmailParsingEvent extends EmailConfigEvent {
  final bool confirm;
  final String token;

  const DisableEmailParsingEvent({
    required this.confirm,
    required this.token,
  });

  @override
  List<Object?> get props => [confirm, token];
}

class UpdateAppPasswordEvent extends EmailConfigEvent {
  final String appPassword;
  final bool consent;
  final String token;

  const UpdateAppPasswordEvent({
    required this.appPassword,
    required this.consent,
    required this.token,
  });

  @override
  List<Object?> get props => [appPassword, consent, token];
}







