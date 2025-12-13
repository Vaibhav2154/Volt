import '../../domain/entities/forecast_period.dart';

class ForecastPeriodModel extends ForecastPeriod {
  const ForecastPeriodModel({
    required super.periodKey,
    required super.startDate,
    required super.endDate,
    required super.bestCase,
    required super.likelyCase,
    required super.worstCase,
    required super.confidence,
    super.isPredictedLean,
  });

  factory ForecastPeriodModel.fromJson(Map<String, dynamic> json) {
    return ForecastPeriodModel(
      periodKey: json['period_key'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      bestCase: (json['best_case'] as num).toDouble(),
      likelyCase: (json['likely_case'] as num).toDouble(),
      worstCase: (json['worst_case'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      isPredictedLean: json['is_predicted_lean'] as bool? ?? false,
    );
  }
}

