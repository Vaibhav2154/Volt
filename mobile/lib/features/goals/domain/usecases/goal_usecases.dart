import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/goal.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_progress.dart';
import '../repositories/goal_repository.dart';

class CreateGoalUseCase implements UseCase<Goal, CreateGoalParams> {
  final GoalRepository repository;

  CreateGoalUseCase(this.repository);

  @override
  Future<Either<Failure, Goal>> call(CreateGoalParams params) async {
    return await repository.createGoal(
      token: params.token,
      title: params.title,
      description: params.description,
      targetAmount: params.targetAmount,
      endDate: params.endDate,
    );
  }
}

class CreateGoalParams {
  final String token;
  final String title;
  final String? description;
  final double targetAmount;
  final DateTime endDate;

  CreateGoalParams({
    required this.token,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.endDate,
  });
}

class GetAllGoalsUseCase implements UseCase<List<Goal>, GetAllGoalsParams> {
  final GoalRepository repository;

  GetAllGoalsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Goal>>> call(GetAllGoalsParams params) async {
    return await repository.getAllGoals(
      token: params.token,
      activeOnly: params.activeOnly,
    );
  }
}

class GetAllGoalsParams {
  final String token;
  final bool activeOnly;

  GetAllGoalsParams({
    required this.token,
    this.activeOnly = false,
  });
}

class GetGoalsWithProgressUseCase
    implements UseCase<List<GoalProgress>, GetGoalsWithProgressParams> {
  final GoalRepository repository;

  GetGoalsWithProgressUseCase(this.repository);

  @override
  Future<Either<Failure, List<GoalProgress>>> call(
      GetGoalsWithProgressParams params) async {
    return await repository.getGoalsWithProgress(
      token: params.token,
      activeOnly: params.activeOnly,
    );
  }
}

class GetGoalsWithProgressParams {
  final String token;
  final bool activeOnly;

  GetGoalsWithProgressParams({
    required this.token,
    this.activeOnly = false,
  });
}

class GetGoalUseCase implements UseCase<GoalDetailed, GetGoalParams> {
  final GoalRepository repository;

  GetGoalUseCase(this.repository);

  @override
  Future<Either<Failure, GoalDetailed>> call(GetGoalParams params) async {
    return await repository.getGoal(
      token: params.token,
      goalId: params.goalId,
    );
  }
}

class GetGoalParams {
  final String token;
  final int goalId;

  GetGoalParams({
    required this.token,
    required this.goalId,
  });
}

class UpdateGoalUseCase implements UseCase<Goal, UpdateGoalParams> {
  final GoalRepository repository;

  UpdateGoalUseCase(this.repository);

  @override
  Future<Either<Failure, Goal>> call(UpdateGoalParams params) async {
    return await repository.updateGoal(
      token: params.token,
      goalId: params.goalId,
      title: params.title,
      description: params.description,
      targetAmount: params.targetAmount,
      currentAmount: params.currentAmount,
      endDate: params.endDate,
      isActive: params.isActive,
      isAchieved: params.isAchieved,
    );
  }
}

class UpdateGoalParams {
  final String token;
  final int goalId;
  final String? title;
  final String? description;
  final double? targetAmount;
  final double? currentAmount;
  final DateTime? endDate;
  final bool? isActive;
  final bool? isAchieved;

  UpdateGoalParams({
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
}

class DeleteGoalUseCase implements UseCase<void, DeleteGoalParams> {
  final GoalRepository repository;

  DeleteGoalUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteGoalParams params) async {
    return await repository.deleteGoal(
      token: params.token,
      goalId: params.goalId,
    );
  }
}

class DeleteGoalParams {
  final String token;
  final int goalId;

  DeleteGoalParams({
    required this.token,
    required this.goalId,
  });
}

class ActivateGoalUseCase implements UseCase<Goal, ActivateGoalParams> {
  final GoalRepository repository;

  ActivateGoalUseCase(this.repository);

  @override
  Future<Either<Failure, Goal>> call(ActivateGoalParams params) async {
    return await repository.activateGoal(
      token: params.token,
      goalId: params.goalId,
    );
  }
}

class ActivateGoalParams {
  final String token;
  final int goalId;

  ActivateGoalParams({
    required this.token,
    required this.goalId,
  });
}

class DeactivateGoalUseCase implements UseCase<Goal, DeactivateGoalParams> {
  final GoalRepository repository;

  DeactivateGoalUseCase(this.repository);

  @override
  Future<Either<Failure, Goal>> call(DeactivateGoalParams params) async {
    return await repository.deactivateGoal(
      token: params.token,
      goalId: params.goalId,
    );
  }
}

class DeactivateGoalParams {
  final String token;
  final int goalId;

  DeactivateGoalParams({
    required this.token,
    required this.goalId,
  });
}

class GetGoalContributionsUseCase
    implements UseCase<List<GoalContribution>, GetGoalContributionsParams> {
  final GoalRepository repository;

  GetGoalContributionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<GoalContribution>>> call(
      GetGoalContributionsParams params) async {
    return await repository.getGoalContributions(
      token: params.token,
      goalId: params.goalId,
    );
  }
}

class GetGoalContributionsParams {
  final String token;
  final int goalId;

  GetGoalContributionsParams({
    required this.token,
    required this.goalId,
  });
}





