import 'package:equatable/equatable.dart';

class HealthScoreRecommendation extends Equatable {
  final String priority; // 'high', 'medium', 'low'
  final String action;
  final String impact;
  final String difficulty; // 'easy', 'moderate', 'challenging'
  final double estimatedScoreGain;

  const HealthScoreRecommendation({
    required this.priority,
    required this.action,
    required this.impact,
    required this.difficulty,
    required this.estimatedScoreGain,
  });

  @override
  List<Object?> get props => [priority, action, impact, difficulty, estimatedScoreGain];
}

