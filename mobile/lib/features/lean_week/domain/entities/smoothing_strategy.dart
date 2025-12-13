import 'package:equatable/equatable.dart';

class SmoothingStrategy extends Equatable {
  final String volatilityLevel;
  final String strategySummary;
  final double leanFrequency;
  final List<String> recommendations;
  final List<String> actionItems;

  const SmoothingStrategy({
    required this.volatilityLevel,
    required this.strategySummary,
    required this.leanFrequency,
    required this.recommendations,
    required this.actionItems,
  });

  @override
  List<Object?> get props => [
        volatilityLevel,
        strategySummary,
        leanFrequency,
        recommendations,
        actionItems,
      ];
}







