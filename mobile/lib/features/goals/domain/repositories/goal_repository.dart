import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/goal.dart';
import '../entities/goal_contribution.dart';
import '../entities/goal_progress.dart';

abstract class GoalRepository {
  Future<Either<Failure, Goal>> createGoal({
    required String token,
    required String title,
    String? description,
    required double targetAmount,
    required DateTime endDate,
  });

  Future<Either<Failure, List<Goal>>> getAllGoals({
    required String token,
    bool activeOnly = false,
  });

  Future<Either<Failure, List<GoalProgress>>> getGoalsWithProgress({
    required String token,
    bool activeOnly = false,
  });

  Future<Either<Failure, GoalDetailed>> getGoal({
    required String token,
    required int goalId,
  });

  Future<Either<Failure, Goal>> updateGoal({
    required String token,
    required int goalId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? endDate,
    bool? isActive,
    bool? isAchieved,
  });

  Future<Either<Failure, void>> deleteGoal({
    required String token,
    required int goalId,
  });

  Future<Either<Failure, Goal>> activateGoal({
    required String token,
    required int goalId,
  });

  Future<Either<Failure, Goal>> deactivateGoal({
    required String token,
    required int goalId,
  });

  Future<Either<Failure, List<GoalContribution>>> getGoalContributions({
    required String token,
    required int goalId,
  });
}







