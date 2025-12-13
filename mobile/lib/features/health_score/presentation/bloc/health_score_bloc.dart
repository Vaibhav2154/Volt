import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_health_score_usecase.dart';
import 'health_score_event.dart';
import 'health_score_state.dart';

class HealthScoreBloc extends Bloc<HealthScoreEvent, HealthScoreState> {
  final GetHealthScoreUseCase getHealthScoreUseCase;

  HealthScoreBloc({
    required this.getHealthScoreUseCase,
  }) : super(HealthScoreInitial()) {
    on<LoadHealthScoreEvent>(_onLoadHealthScore);
    on<RefreshHealthScoreEvent>(_onRefreshHealthScore);
  }

  Future<void> _onLoadHealthScore(
    LoadHealthScoreEvent event,
    Emitter<HealthScoreState> emit,
  ) async {
    emit(HealthScoreLoading());

    final result = await getHealthScoreUseCase(
      GetHealthScoreParams(
        token: event.token,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(HealthScoreError(failure.message)),
      (score) => emit(HealthScoreLoaded(score)),
    );
  }

  Future<void> _onRefreshHealthScore(
    RefreshHealthScoreEvent event,
    Emitter<HealthScoreState> emit,
  ) async {
    final result = await getHealthScoreUseCase(
      GetHealthScoreParams(
        token: event.token,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(HealthScoreError(failure.message)),
      (score) => emit(HealthScoreLoaded(score)),
    );
  }
}

