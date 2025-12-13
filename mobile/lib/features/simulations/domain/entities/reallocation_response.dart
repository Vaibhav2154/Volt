import 'package:equatable/equatable.dart';

class CategoryReallocation extends Equatable {
  final String category;
  final double currentMonthly;
  final double changeAmount;
  final double newMonthly;
  final double changePercent;
  final String feasibility; // "comfortable", "moderate", "difficult", "unrealistic"
  final String impactNote;

  const CategoryReallocation({
    required this.category,
    required this.currentMonthly,
    required this.changeAmount,
    required this.newMonthly,
    required this.changePercent,
    required this.feasibility,
    required this.impactNote,
  });

  @override
  List<Object?> get props => [
        category,
        currentMonthly,
        changeAmount,
        newMonthly,
        changePercent,
        feasibility,
        impactNote,
      ];
}

class ReallocationResponse extends Equatable {
  final double baselineMonthly;
  final double projectedMonthly;
  final bool isBalanced;
  final List<CategoryReallocation> reallocations;
  final String feasibilityAssessment;
  final List<String> warnings;
  final List<String> recommendations;
  final Map<String, dynamic> visualData;

  const ReallocationResponse({
    required this.baselineMonthly,
    required this.projectedMonthly,
    required this.isBalanced,
    required this.reallocations,
    required this.feasibilityAssessment,
    required this.warnings,
    required this.recommendations,
    required this.visualData,
  });

  @override
  List<Object?> get props => [
        baselineMonthly,
        projectedMonthly,
        isBalanced,
        reallocations,
        feasibilityAssessment,
        warnings,
        recommendations,
        visualData,
      ];
}







