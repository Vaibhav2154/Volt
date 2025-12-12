import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_gamification_feed_usecase.dart';
import '../../domain/usecases/get_gamification_profile_usecase.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GetGamificationProfileUseCase getProfileUseCase;
  final GetGamificationFeedUseCase getFeedUseCase;

  GamificationBloc({
    required this.getProfileUseCase,
    required this.getFeedUseCase,
  }) : super(GamificationInitial()) {
    on<LoadGamificationProfileEvent>(_onLoadProfile);
    on<RefreshGamificationProfileEvent>(_onRefreshProfile);
    on<LoadGamificationFeedEvent>(_onLoadFeed);
  }

  Future<void> _onLoadProfile(
    LoadGamificationProfileEvent event,
    Emitter<GamificationState> emit,
  ) async {
    emit(GamificationLoading());

    final result = await getProfileUseCase();

    result.fold(
      (failure) => emit(GamificationError(failure.message)),
      (profile) => emit(GamificationProfileLoaded(profile)),
    );
  }

  Future<void> _onRefreshProfile(
    RefreshGamificationProfileEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final result = await getProfileUseCase();

    result.fold(
      (failure) => emit(GamificationError(failure.message)),
      (profile) => emit(GamificationProfileLoaded(profile)),
    );
  }

  Future<void> _onLoadFeed(
    LoadGamificationFeedEvent event,
    Emitter<GamificationState> emit,
  ) async {
    emit(GamificationLoading());

    final result = await getFeedUseCase(limit: event.limit);

    result.fold(
      (failure) => emit(GamificationError(failure.message)),
      (feed) => emit(GamificationFeedLoaded(feed)),
    );
  }
}

