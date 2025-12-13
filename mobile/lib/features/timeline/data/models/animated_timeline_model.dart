import '../../domain/entities/animated_timeline.dart';
import 'cash_flow_period_model.dart';
import 'forecast_period_model.dart';
import 'timeline_statistics_model.dart';
import 'welford_calculation_model.dart';

class AnimatedTimelineModel extends AnimatedTimeline {
  const AnimatedTimelineModel({
    required super.timelineType,
    required super.historicalPeriods,
    required super.forecastPeriods,
    required super.statistics,
    super.welfordStats,
    super.animationDurationMs,
    super.highlightLeanPeriods,
    required super.userId,
    required super.generatedAt,
    required super.periodCount,
  });

  factory AnimatedTimelineModel.fromJson(Map<String, dynamic> json) {
    return AnimatedTimelineModel(
      timelineType: json['timeline_type'] as String,
      historicalPeriods: (json['historical_periods'] as List<dynamic>)
          .map((e) => CashFlowPeriodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      forecastPeriods: (json['forecast_periods'] as List<dynamic>?)
              ?.map((e) => ForecastPeriodModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      statistics: TimelineStatisticsModel.fromJson(
        json['statistics'] as Map<String, dynamic>,
      ),
      welfordStats: json['welford_stats'] != null
          ? WelfordCalculationModel.fromJson(
              json['welford_stats'] as Map<String, dynamic>,
            )
          : null,
      animationDurationMs: json['animation_duration_ms'] as int? ?? 2000,
      highlightLeanPeriods: json['highlight_lean_periods'] as bool? ?? true,
      userId: json['user_id'] as int,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      periodCount: json['period_count'] as int,
    );
  }
}

