import 'package:equatable/equatable.dart';

class CategoryAnalysis extends Equatable {
  final double currentMonthly;
  final double maxReductionPct;
  final double achievableReductionPct;
  final double monthlySavings;
  final double confidence;
  final String difficulty; // "easy", "moderate", "challenging"

  const CategoryAnalysis({
    required this.currentMonthly,
    required this.maxReductionPct,
    required this.achievableReductionPct,
    required this.monthlySavings,
    required this.confidence,
    required this.difficulty,
  });

  @override
  List<Object?> get props => [
        currentMonthly,
        maxReductionPct,
        achievableReductionPct,
        monthlySavings,
        confidence,
        difficulty,
      ];
}

