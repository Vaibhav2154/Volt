import 'package:equatable/equatable.dart';
import 'lean_period.dart';

class LeanPattern extends Equatable {
  final bool hasPattern;
  final String? patternType;
  final String description;

  const LeanPattern({
    required this.hasPattern,
    this.patternType,
    required this.description,
  });

  @override
  List<Object?> get props => [hasPattern, patternType, description];
}

class LeanAnalysis extends Equatable {
  final List<LeanPeriod> leanPeriods;
  final double leanFrequency;
  final double avgLeanSeverity;
  final LeanPattern patternDetected;
  final double threshold;

  const LeanAnalysis({
    required this.leanPeriods,
    required this.leanFrequency,
    required this.avgLeanSeverity,
    required this.patternDetected,
    required this.threshold,
  });

  @override
  List<Object?> get props => [
        leanPeriods,
        leanFrequency,
        avgLeanSeverity,
        patternDetected,
        threshold,
      ];
}






