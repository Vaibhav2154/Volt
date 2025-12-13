import 'package:equatable/equatable.dart';

class HealthScoreFactors extends Equatable {
  final List<String> positiveFactors;
  final List<String> negativeFactors;
  final List<String> criticalIssues;

  const HealthScoreFactors({
    required this.positiveFactors,
    required this.negativeFactors,
    required this.criticalIssues,
  });

  @override
  List<Object?> get props => [positiveFactors, negativeFactors, criticalIssues];
}

