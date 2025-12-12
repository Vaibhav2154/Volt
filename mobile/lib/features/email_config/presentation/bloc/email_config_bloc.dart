import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/disable_email_parsing_usecase.dart';
import '../../domain/usecases/get_email_parsing_status_usecase.dart';
import '../../domain/usecases/setup_app_password_usecase.dart';
import '../../domain/usecases/update_app_password_usecase.dart';
import 'email_config_event.dart';
import 'email_config_state.dart';

class EmailConfigBloc extends Bloc<EmailConfigEvent, EmailConfigState> {
  final SetupAppPasswordUseCase setupAppPasswordUseCase;
  final GetEmailParsingStatusUseCase getEmailParsingStatusUseCase;
  final DisableEmailParsingUseCase disableEmailParsingUseCase;
  final UpdateAppPasswordUseCase updateAppPasswordUseCase;

  EmailConfigBloc({
    required this.setupAppPasswordUseCase,
    required this.getEmailParsingStatusUseCase,
    required this.disableEmailParsingUseCase,
    required this.updateAppPasswordUseCase,
  }) : super(EmailConfigInitial()) {
    on<SetupAppPasswordEvent>(_onSetupAppPassword);
    on<GetEmailParsingStatusEvent>(_onGetEmailParsingStatus);
    on<DisableEmailParsingEvent>(_onDisableEmailParsing);
    on<UpdateAppPasswordEvent>(_onUpdateAppPassword);
  }

  Future<void> _onSetupAppPassword(
    SetupAppPasswordEvent event,
    Emitter<EmailConfigState> emit,
  ) async {
    emit(EmailConfigLoading());

    final result = await setupAppPasswordUseCase(
      SetupAppPasswordParams(
        appPassword: event.appPassword,
        consent: event.consent,
        token: event.token,
      ),
    );

    result.fold(
      (failure) => emit(EmailConfigError(failure.message)),
      (response) => emit(EmailAppPasswordSetupSuccess(response)),
    );
  }

  Future<void> _onGetEmailParsingStatus(
    GetEmailParsingStatusEvent event,
    Emitter<EmailConfigState> emit,
  ) async {
    emit(EmailConfigLoading());

    final result = await getEmailParsingStatusUseCase(event.token);

    result.fold(
      (failure) => emit(EmailConfigError(failure.message)),
      (status) => emit(EmailParsingStatusLoaded(status)),
    );
  }

  Future<void> _onDisableEmailParsing(
    DisableEmailParsingEvent event,
    Emitter<EmailConfigState> emit,
  ) async {
    emit(EmailConfigLoading());

    final result = await disableEmailParsingUseCase(
      DisableEmailParsingParams(
        confirm: event.confirm,
        token: event.token,
      ),
    );

    result.fold(
      (failure) => emit(EmailConfigError(failure.message)),
      (response) => emit(EmailParsingDisabledSuccess(response)),
    );
  }

  Future<void> _onUpdateAppPassword(
    UpdateAppPasswordEvent event,
    Emitter<EmailConfigState> emit,
  ) async {
    emit(EmailConfigLoading());

    final result = await updateAppPasswordUseCase(
      UpdateAppPasswordParams(
        appPassword: event.appPassword,
        consent: event.consent,
        token: event.token,
      ),
    );

    result.fold(
      (failure) => emit(EmailConfigError(failure.message)),
      (response) => emit(EmailAppPasswordSetupSuccess(response)),
    );
  }
}

