import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_cash_flow_forecast_usecase.dart';
import '../../domain/usecases/get_income_smoothing_recommendations_usecase.dart';
import '../../domain/usecases/get_lean_week_analysis_usecase.dart';
import 'lean_week_event.dart';
import 'lean_week_state.dart';

class LeanWeekBloc extends Bloc<LeanWeekEvent, LeanWeekState> {
  final GetLeanWeekAnalysisUseCase getLeanWeekAnalysisUseCase;
  final GetCashFlowForecastUseCase getCashFlowForecastUseCase;
  final GetIncomeSmoothingRecommendationsUseCase
      getIncomeSmoothingRecommendationsUseCase;

  LeanWeekBloc({
    required this.getLeanWeekAnalysisUseCase,
    required this.getCashFlowForecastUseCase,
    required this.getIncomeSmoothingRecommendationsUseCase,
  }) : super(LeanWeekInitial()) {
    on<GetLeanWeekAnalysisEvent>(_onGetLeanWeekAnalysis);
    on<GetCashFlowForecastEvent>(_onGetCashFlowForecast);
    on<GetIncomeSmoothingRecommendationsEvent>(
        _onGetIncomeSmoothingRecommendations);
  }

  Future<void> _onGetLeanWeekAnalysis(
    GetLeanWeekAnalysisEvent event,
    Emitter<LeanWeekState> emit,
  ) async {
    emit(LeanWeekLoading());

    final result = await getLeanWeekAnalysisUseCase(
      GetLeanWeekAnalysisParams(
        token: event.token,
        currentBalance: event.currentBalance,
      ),
    );

    result.fold(
      (failure) => emit(LeanWeekError(failure.message)),
      (analysis) => emit(LeanWeekAnalysisLoaded(analysis)),
    );
  }

  Future<void> _onGetCashFlowForecast(
    GetCashFlowForecastEvent event,
    Emitter<LeanWeekState> emit,
  ) async {
    emit(LeanWeekLoading());

    final result = await getCashFlowForecastUseCase(
      GetCashFlowForecastParams(
        token: event.token,
        periods: event.periods,
        currentBalance: event.currentBalance,
      ),
    );

    result.fold(
      (failure) => emit(LeanWeekError(failure.message)),
      (forecast) => emit(CashFlowForecastLoaded(forecast)),
    );
  }

  Future<void> _onGetIncomeSmoothingRecommendations(
    GetIncomeSmoothingRecommendationsEvent event,
    Emitter<LeanWeekState> emit,
  ) async {
    emit(LeanWeekLoading());

    final result = await getIncomeSmoothingRecommendationsUseCase(
      GetIncomeSmoothingRecommendationsParams(
        token: event.token,
        currentBalance: event.currentBalance,
        targetMonths: event.targetMonths,
      ),
    );

    result.fold(
      (failure) => emit(LeanWeekError(failure.message)),
      (recommendations) =>
          emit(IncomeSmoothingRecommendationsLoaded(recommendations)),
    );
  }
}





