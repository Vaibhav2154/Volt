import 'package:equatable/equatable.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();

  @override
  List<Object?> get props => [];
}

class LoadGoalsEvent extends GoalEvent {
  final String token;
  final bool activeOnly;

  const LoadGoalsEvent({
    required this.token,
    this.activeOnly = false,
  });

  @override
  List<Object?> get props => [token, activeOnly];
}

class LoadGoalsWithProgressEvent extends GoalEvent {
  final String token;
  final bool activeOnly;

  const LoadGoalsWithProgressEvent({
    required this.token,
    this.activeOnly = false,
  });

  @override
  List<Object?> get props => [token, activeOnly];
}

class LoadGoalEvent extends GoalEvent {
  final String token;
  final int goalId;

  const LoadGoalEvent({
    required this.token,
    required this.goalId,
  });

  @override
  List<Object?> get props => [token, goalId];
}

class CreateGoalEvent extends GoalEvent {
  final String token;
  final String title;
  final String? description;
  final double targetAmount;
  final DateTime endDate;

  const CreateGoalEvent({
    required this.token,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.endDate,
  });

  @override
  List<Object?> get props => [token, title, description, targetAmount, endDate];
}

class UpdateGoalEvent extends GoalEvent {
  final String token;
  final int goalId;
  final String? title;
  final String? description;
  final double? targetAmount;
  final double? currentAmount;
  final DateTime? endDate;
  final bool? isActive;
  final bool? isAchieved;

  const UpdateGoalEvent({
    required this.token,
    required this.goalId,
    this.title,
    this.description,
    this.targetAmount,
    this.currentAmount,
    this.endDate,
    this.isActive,
    this.isAchieved,
  });

  @override
  List<Object?> get props =>
      [token, goalId, title, description, targetAmount, currentAmount, endDate, isActive, isAchieved];
}

class DeleteGoalEvent extends GoalEvent {
  final String token;
  final int goalId;

  const DeleteGoalEvent({
    required this.token,
    required this.goalId,
  });

  @override
  List<Object?> get props => [token, goalId];
}

class ActivateGoalEvent extends GoalEvent {
  final String token;
  final int goalId;

  const ActivateGoalEvent({
    required this.token,
    required this.goalId,
  });

  @override
  List<Object?> get props => [token, goalId];
}

class DeactivateGoalEvent extends GoalEvent {
  final String token;
  final int goalId;

  const DeactivateGoalEvent({
    required this.token,
    required this.goalId,
  });

  @override
  List<Object?> get props => [token, goalId];
}

class LoadGoalContributionsEvent extends GoalEvent {
  final String token;
  final int goalId;

  const LoadGoalContributionsEvent({
    required this.token,
    required this.goalId,
  });

  @override
  List<Object?> get props => [token, goalId];
}






