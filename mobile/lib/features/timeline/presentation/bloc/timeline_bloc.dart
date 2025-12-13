import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_animated_timeline_usecase.dart';
import 'timeline_event.dart';
import 'timeline_state.dart';

class TimelineBloc extends Bloc<TimelineEvent, TimelineState> {
  final GetAnimatedTimelineUseCase getAnimatedTimelineUseCase;

  TimelineBloc({
    required this.getAnimatedTimelineUseCase,
  }) : super(TimelineInitial()) {
    on<LoadTimelineEvent>(_onLoadTimeline);
    on<RefreshTimelineEvent>(_onRefreshTimeline);
  }

  Future<void> _onLoadTimeline(
    LoadTimelineEvent event,
    Emitter<TimelineState> emit,
  ) async {
    emit(TimelineLoading());

    final result = await getAnimatedTimelineUseCase(
      GetAnimatedTimelineParams(
        token: event.token,
        userId: event.userId,
        timelineType: event.timelineType,
        periods: event.periods,
        includeForecast: event.includeForecast,
      ),
    );

    result.fold(
      (failure) => emit(TimelineError(failure.message)),
      (timeline) => emit(TimelineLoaded(timeline)),
    );
  }

  Future<void> _onRefreshTimeline(
    RefreshTimelineEvent event,
    Emitter<TimelineState> emit,
  ) async {
    final result = await getAnimatedTimelineUseCase(
      GetAnimatedTimelineParams(
        token: event.token,
        userId: event.userId,
        timelineType: event.timelineType,
        periods: event.periods,
        includeForecast: event.includeForecast,
      ),
    );

    result.fold(
      (failure) => emit(TimelineError(failure.message)),
      (timeline) => emit(TimelineLoaded(timeline)),
    );
  }
}

