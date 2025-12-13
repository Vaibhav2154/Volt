import 'package:equatable/equatable.dart';

class ForecastPeriod extends Equatable {
  final String periodKey;
  final DateTime startDate;
  final DateTime endDate;
  final double bestCase;
  final double likelyCase;
  final double worstCase;
  final double confidence;
  final bool isPredictedLean;

  const ForecastPeriod({
    required this.periodKey,
    required this.startDate,
    required this.endDate,
    required this.bestCase,
    required this.likelyCase,
    required this.worstCase,
    required this.confidence,
    this.isPredictedLean = false,
  });

  @override
  List<Object?> get props => [
        periodKey,
        startDate,
        endDate,
        bestCase,
        likelyCase,
        worstCase,
        confidence,
        isPredictedLean,
      ];
}

