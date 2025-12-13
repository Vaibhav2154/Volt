import 'package:equatable/equatable.dart';

class HealthScoreComparison extends Equatable {
  final int percentile;
  final String comparisonText;
  final double avgScore;

  const HealthScoreComparison({
    required this.percentile,
    required this.comparisonText,
    required this.avgScore,
  });

  @override
  List<Object?> get props => [percentile, comparisonText, avgScore];
}

