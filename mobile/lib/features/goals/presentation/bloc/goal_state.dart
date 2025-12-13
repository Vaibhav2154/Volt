import 'package:equatable/equatable.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/goal_progress.dart';

abstract class GoalState extends Equatable {
  const GoalState();

  @override
  List<Object?> get props => [];
}

class GoalInitial extends GoalState {}

class GoalLoading extends GoalState {}

class GoalsLoaded extends GoalState {
  final List<Goal> goals;

  const GoalsLoaded(this.goals);

  @override
  List<Object?> get props => [goals];
}

class GoalsWithProgressLoaded extends GoalState {
  final List<GoalProgress> goals;

  const GoalsWithProgressLoaded(this.goals);

  @override
  List<Object?> get props => [goals];
}

class GoalLoaded extends GoalState {
  final GoalDetailed goal;

  const GoalLoaded(this.goal);

  @override
  List<Object?> get props => [goal];
}

class GoalCreated extends GoalState {
  final Goal goal;

  const GoalCreated(this.goal);

  @override
  List<Object?> get props => [goal];
}

class GoalUpdated extends GoalState {
  final Goal goal;

  const GoalUpdated(this.goal);

  @override
  List<Object?> get props => [goal];
}

class GoalDeleted extends GoalState {
  final int goalId;

  const GoalDeleted(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class GoalActivated extends GoalState {
  final Goal goal;

  const GoalActivated(this.goal);

  @override
  List<Object?> get props => [goal];
}

class GoalDeactivated extends GoalState {
  final Goal goal;

  const GoalDeactivated(this.goal);

  @override
  List<Object?> get props => [goal];
}

class GoalContributionsLoaded extends GoalState {
  final List<GoalContribution> contributions;

  const GoalContributionsLoaded(this.contributions);

  @override
  List<Object?> get props => [contributions];
}

class GoalError extends GoalState {
  final String message;

  const GoalError(this.message);

  @override
  List<Object?> get props => [message];
}







