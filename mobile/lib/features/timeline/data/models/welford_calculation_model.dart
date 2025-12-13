import '../../domain/entities/welford_calculation.dart';

class WelfordCalculationModel extends WelfordCalculation {
  const WelfordCalculationModel({
    required super.sampleCount,
    required super.runningMean,
    required super.runningVariance,
    required super.runningStdDev,
    super.algorithmName,
    super.isNumericallyStable,
  });

  factory WelfordCalculationModel.fromJson(Map<String, dynamic> json) {
    return WelfordCalculationModel(
      sampleCount: json['sample_count'] as int,
      runningMean: (json['running_mean'] as num).toDouble(),
      runningVariance: (json['running_variance'] as num).toDouble(),
      runningStdDev: (json['running_std_dev'] as num).toDouble(),
      algorithmName: json['algorithm_name'] as String? ?? "Welford's Online Algorithm",
      isNumericallyStable: json['is_numerically_stable'] as bool? ?? true,
    );
  }
}

