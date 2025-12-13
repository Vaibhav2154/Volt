import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/goal_usecases.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final CreateGoalUseCase createGoalUseCase;
  final GetAllGoalsUseCase getAllGoalsUseCase;
  final GetGoalsWithProgressUseCase getGoalsWithProgressUseCase;
  final GetGoalUseCase getGoalUseCase;
  final UpdateGoalUseCase updateGoalUseCase;
  final DeleteGoalUseCase deleteGoalUseCase;
  final ActivateGoalUseCase activateGoalUseCase;
  final DeactivateGoalUseCase deactivateGoalUseCase;
  final GetGoalContributionsUseCase getGoalContributionsUseCase;

  GoalBloc({
    required this.createGoalUseCase,
    required this.getAllGoalsUseCase,
    required this.getGoalsWithProgressUseCase,
    required this.getGoalUseCase,
    required this.updateGoalUseCase,
    required this.deleteGoalUseCase,
    required this.activateGoalUseCase,
    required this.deactivateGoalUseCase,
    required this.getGoalContributionsUseCase,
  }) : super(GoalInitial()) {
    on<LoadGoalsEvent>(_onLoadGoals);
    on<LoadGoalsWithProgressEvent>(_onLoadGoalsWithProgress);
    on<LoadGoalEvent>(_onLoadGoal);
    on<CreateGoalEvent>(_onCreateGoal);
    on<UpdateGoalEvent>(_onUpdateGoal);
    on<DeleteGoalEvent>(_onDeleteGoal);
    on<ActivateGoalEvent>(_onActivateGoal);
    on<DeactivateGoalEvent>(_onDeactivateGoal);
    on<LoadGoalContributionsEvent>(_onLoadGoalContributions);
  }

  Future<void> _onLoadGoals(
    LoadGoalsEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await getAllGoalsUseCase(
      GetAllGoalsParams(
        token: event.token,
        activeOnly: event.activeOnly,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goals) => emit(GoalsLoaded(goals)),
    );
  }

  Future<void> _onLoadGoalsWithProgress(
    LoadGoalsWithProgressEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await getGoalsWithProgressUseCase(
      GetGoalsWithProgressParams(
        token: event.token,
        activeOnly: event.activeOnly,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goals) => emit(GoalsWithProgressLoaded(goals)),
    );
  }

  Future<void> _onLoadGoal(
    LoadGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await getGoalUseCase(
      GetGoalParams(
        token: event.token,
        goalId: event.goalId,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) => emit(GoalLoaded(goal)),
    );
  }

  Future<void> _onCreateGoal(
    CreateGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await createGoalUseCase(
      CreateGoalParams(
        token: event.token,
        title: event.title,
        description: event.description,
        targetAmount: event.targetAmount,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) => emit(GoalCreated(goal)),
    );
  }

  Future<void> _onUpdateGoal(
    UpdateGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await updateGoalUseCase(
      UpdateGoalParams(
        token: event.token,
        goalId: event.goalId,
        title: event.title,
        description: event.description,
        targetAmount: event.targetAmount,
        currentAmount: event.currentAmount,
        endDate: event.endDate,
        isActive: event.isActive,
        isAchieved: event.isAchieved,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) => emit(GoalUpdated(goal)),
    );
  }

  Future<void> _onDeleteGoal(
    DeleteGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await deleteGoalUseCase(
      DeleteGoalParams(
        token: event.token,
        goalId: event.goalId,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (_) => emit(GoalDeleted(event.goalId)),
    );
  }

  Future<void> _onActivateGoal(
    ActivateGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await activateGoalUseCase(
      ActivateGoalParams(
        token: event.token,
        goalId: event.goalId,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) => emit(GoalActivated(goal)),
    );
  }

  Future<void> _onDeactivateGoal(
    DeactivateGoalEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await deactivateGoalUseCase(
      DeactivateGoalParams(
        token: event.token,
        goalId: event.goalId,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (goal) => emit(GoalDeactivated(goal)),
    );
  }

  Future<void> _onLoadGoalContributions(
    LoadGoalContributionsEvent event,
    Emitter<GoalState> emit,
  ) async {
    emit(GoalLoading());

    final result = await getGoalContributionsUseCase(
      GetGoalContributionsParams(
        token: event.token,
        goalId: event.goalId,
      ),
    );

    result.fold(
      (failure) => emit(GoalError(failure.message)),
      (contributions) => emit(GoalContributionsLoaded(contributions)),
    );
  }
}






