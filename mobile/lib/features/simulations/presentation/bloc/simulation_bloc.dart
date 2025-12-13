import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/compare_scenarios_refined_usecase.dart';
import '../../domain/usecases/compare_scenarios_usecase.dart';
import '../../domain/usecases/project_future_spending_usecase.dart';
import '../../domain/usecases/simulate_reallocation_usecase.dart';
import '../../domain/usecases/simulate_spending_enhanced_usecase.dart';
import '../../domain/usecases/simulate_spending_refined_usecase.dart';
import '../../domain/usecases/simulate_spending_usecase.dart';
import 'simulation_event.dart';
import 'simulation_state.dart';

class SimulationBloc extends Bloc<SimulationEvent, SimulationState> {
  final SimulateSpendingUseCase simulateSpendingUseCase;
  final SimulateSpendingEnhancedUseCase simulateSpendingEnhancedUseCase;
  final SimulateSpendingRefinedUseCase simulateSpendingRefinedUseCase;
  final CompareScenariosUseCase compareScenariosUseCase;
  final CompareScenariosRefinedUseCase compareScenariosRefinedUseCase;
  final SimulateReallocationUseCase simulateReallocationUseCase;
  final ProjectFutureSpendingUseCase projectFutureSpendingUseCase;

  SimulationBloc({
    required this.simulateSpendingUseCase,
    required this.simulateSpendingEnhancedUseCase,
    required this.simulateSpendingRefinedUseCase,
    required this.compareScenariosUseCase,
    required this.compareScenariosRefinedUseCase,
    required this.simulateReallocationUseCase,
    required this.projectFutureSpendingUseCase,
  }) : super(SimulationInitial()) {
    on<SimulateSpendingEvent>(_onSimulateSpending);
    on<SimulateSpendingEnhancedEvent>(_onSimulateSpendingEnhanced);
    on<SimulateSpendingRefinedEvent>(_onSimulateSpendingRefined);
    on<CompareScenariosEvent>(_onCompareScenarios);
    on<CompareScenariosRefinedEvent>(_onCompareScenariosRefined);
    on<SimulateReallocationEvent>(_onSimulateReallocation);
    on<ProjectFutureSpendingEvent>(_onProjectFutureSpending);
  }

  Future<void> _onSimulateSpending(
    SimulateSpendingEvent event,
    Emitter<SimulationState> emit,
  ) async {
    emit(SimulationLoading());

    final result = await simulateSpendingUseCase(
      SimulateSpendingParams(
        token: event.token,
        userId: event.userId,
        scenarioType: event.scenarioType,
        targetPercent: event.targetPercent,
        timePeriodDays: event.timePeriodDays,
        targetCategories: event.targetCategories,
      ),
    );

    result.fold(
      (failure) => emit(SimulationError(failure.message)),
      (response) => emit(SimulationLoaded(response)),
    );
  }

  Future<void> _onSimulateSpendingEnhanced(
    SimulateSpendingEnhancedEvent event,
    Emitter<SimulationState> emit,
  ) async {
    emit(SimulationLoading());

    final result = await simulateSpendingEnhancedUseCase(
      SimulateSpendingEnhancedParams(
        token: event.token,
        userId: event.userId,
        scenarioType: event.scenarioType,
        targetPercent: event.targetPercent,
        timePeriodDays: event.timePeriodDays,
        targetCategories: event.targetCategories,
      ),
    );

    result.fold(
      (failure) => emit(SimulationError(failure.message)),
      (insight) => emit(SimulationEnhancedLoaded(insight)),
    );
  }

  Future<void> _onSimulateSpendingRefined(
    SimulateSpendingRefinedEvent event,
    Emitter<SimulationState> emit,
  ) async {
    emit(SimulationLoading());

    final result = await simulateSpendingRefinedUseCase(
      SimulateSpendingRefinedParams(
        token: event.token,
        userId: event.userId,
        scenarioType: event.scenarioType,
        targetPercent: event.targetPercent,
        timePeriodDays: event.timePeriodDays,
        targetCategories: event.targetCategories,
      ),
    );

    result.fold(
      (failure) => emit(SimulationError(failure.message)),
      (response) => emit(SimulationRefinedLoaded(response)),
    );
  }

  Future<void> _onCompareScenarios(
    CompareScenariosEvent event,
    Emitter<SimulationState> emit,
  ) async {
    emit(SimulationLoading());

    final result = await compareScenariosUseCase(
      CompareScenariosParams(
        token: event.token,
        userId: event.userId,
        scenarioType: event.scenarioType,
        timePeriodDays: event.timePeriodDays,
        numScenarios: event.numScenarios,
      ),
    );

    result.fold(
      (failure) => emit(SimulationError(failure.message)),
      (comparison) => emit(ScenariosCompared(comparison)),
    );
  }

  Future<void> _onCompareScenariosRefined(
    CompareScenariosRefinedEvent event,
    Emitter<SimulationState> emit,
  ) async {
    emit(SimulationLoading());

    final result = await compareScenariosRefinedUseCase(
      CompareScenariosRefinedParams(
        token: event.token,
        userId: event.userId,
        scenarioType: event.scenarioType,
        timePeriodDays: event.timePeriodDays,
        numScenarios: event.numScenarios,
      ),
    );

    result.fold(
      (failure) => emit(SimulationError(failure.message)),
      (response) => emit(ComparisonRefinedLoaded(response)),
    );
  }

  Future<void> _onSimulateReallocation(
    SimulateReallocationEvent event,
    Emitter<SimulationState> emit,
  ) async {
    emit(SimulationLoading());

    final result = await simulateReallocationUseCase(
      SimulateReallocationParams(
        token: event.token,
        userId: event.userId,
        reallocations: event.reallocations,
        timePeriodDays: event.timePeriodDays,
      ),
    );

    result.fold(
      (failure) => emit(SimulationError(failure.message)),
      (response) => emit(ReallocationSimulated(response)),
    );
  }

  Future<void> _onProjectFutureSpending(
    ProjectFutureSpendingEvent event,
    Emitter<SimulationState> emit,
  ) async {
    emit(SimulationLoading());

    final result = await projectFutureSpendingUseCase(
      ProjectFutureSpendingParams(
        token: event.token,
        userId: event.userId,
        projectionMonths: event.projectionMonths,
        timePeriodDays: event.timePeriodDays,
        scenarioId: event.scenarioId,
        behavioralChanges: event.behavioralChanges,
      ),
    );

    result.fold(
      (failure) => emit(SimulationError(failure.message)),
      (response) => emit(FutureSpendingProjected(response)),
    );
  }
}





