import 'package:equatable/equatable.dart';

class GoalContribution extends Equatable {
  final int id;
  final int goalId;
  final int transactionId;
  final double amount;
  final DateTime createdAt;

  const GoalContribution({
    required this.id,
    required this.goalId,
    required this.transactionId,
    required this.amount,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, goalId, transactionId, amount, createdAt];
}






