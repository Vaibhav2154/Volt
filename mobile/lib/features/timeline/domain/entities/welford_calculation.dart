import 'package:equatable/equatable.dart';

class WelfordCalculation extends Equatable {
  final int sampleCount;
  final double runningMean;
  final double runningVariance;
  final double runningStdDev;
  final String algorithmName;
  final bool isNumericallyStable;

  const WelfordCalculation({
    required this.sampleCount,
    required this.runningMean,
    required this.runningVariance,
    required this.runningStdDev,
    this.algorithmName = "Welford's Online Algorithm",
    this.isNumericallyStable = true,
  });

  @override
  List<Object?> get props => [
        sampleCount,
        runningMean,
        runningVariance,
        runningStdDev,
        algorithmName,
        isNumericallyStable,
      ];
}

