import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/is_authenticated_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final IsAuthenticatedUseCase isAuthenticatedUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.isAuthenticatedUseCase,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<GetCurrentUserEvent>(_onGetCurrentUser);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    // Always start fresh from loading state
    emit(AuthLoading());

    final loginResult = await loginUseCase(
      LoginParams(
        email: event.email,
        password: event.password,
      ),
    );

    // Handle login result sequentially
    final loginFailure = loginResult.fold<Failure?>(
      (failure) => failure,
      (tokens) => null,
    );

    if (loginFailure != null) {
      if (!emit.isDone) {
        emit(AuthError(loginFailure.message));
      }
      return;
    }

    // Login successful - the repository already cached the user during login
    // Get user data (will use cached user if available)
    final userResult = await getCurrentUserUseCase(NoParams());
    
    // Check if emitter is still active before emitting
    if (emit.isDone) {
      return;
    }
    
    // Extract user or failure
    final userFailure = userResult.fold<Failure?>(
      (failure) => failure,
      (user) => null,
    );
    
    if (userFailure != null) {
      if (!emit.isDone) {
        emit(AuthError(userFailure.message));
      }
      return;
    }
    
    // Extract user
    final user = userResult.fold<User?>(
      (failure) => null,
      (user) => user,
    );
    
    if (user != null && !emit.isDone) {
      emit(AuthAuthenticated(user));
    } else if (user == null && !emit.isDone) {
      emit(AuthError('Failed to get user data'));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await registerUseCase(
      RegisterParams(
        name: event.name,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthRegistrationSuccess(user)),
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final isAuthenticated = await isAuthenticatedUseCase();

    if (isAuthenticated) {
      final result = await getCurrentUserUseCase(NoParams());
      result.fold(
        (failure) => emit(AuthUnauthenticated()),
        (user) => emit(AuthAuthenticated(user)),
      );
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGetCurrentUser(
    GetCurrentUserEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    final result = await getCurrentUserUseCase(NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
