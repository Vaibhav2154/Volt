import 'package:equatable/equatable.dart';
import '../../domain/entities/financial_health_score.dart';

abstract class HealthScoreState extends Equatable {
  const HealthScoreState();

  @override
  List<Object?> get props => [];
}

class HealthScoreInitial extends HealthScoreState {}

class HealthScoreLoading extends HealthScoreState {}

class HealthScoreLoaded extends HealthScoreState {
  final FinancialHealthScore score;

  const HealthScoreLoaded(this.score);

  @override
  List<Object?> get props => [score];
}

class HealthScoreError extends HealthScoreState {
  final String message;

  const HealthScoreError(this.message);

  @override
  List<Object?> get props => [message];
}

