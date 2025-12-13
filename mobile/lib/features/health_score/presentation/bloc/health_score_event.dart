import 'package:equatable/equatable.dart';

abstract class HealthScoreEvent extends Equatable {
  const HealthScoreEvent();

  @override
  List<Object?> get props => [];
}

class LoadHealthScoreEvent extends HealthScoreEvent {
  final String token;
  final int userId;

  const LoadHealthScoreEvent({
    required this.token,
    required this.userId,
  });

  @override
  List<Object?> get props => [token, userId];
}

class RefreshHealthScoreEvent extends HealthScoreEvent {
  final String token;
  final int userId;

  const RefreshHealthScoreEvent({
    required this.token,
    required this.userId,
  });

  @override
  List<Object?> get props => [token, userId];
}

