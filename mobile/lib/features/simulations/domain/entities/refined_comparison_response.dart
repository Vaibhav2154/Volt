import 'package:equatable/equatable.dart';
import 'scenario_comparison.dart';

class RefinedComparisonResponse extends Equatable {
  final ScenarioComparisonResponse comparison;
  final String refinedInsight; // Markdown string

  const RefinedComparisonResponse({
    required this.comparison,
    required this.refinedInsight,
  });

  @override
  List<Object?> get props => [comparison, refinedInsight];
}

