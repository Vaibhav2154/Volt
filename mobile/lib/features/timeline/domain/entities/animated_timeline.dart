import 'package:equatable/equatable.dart';
import 'cash_flow_period.dart';
import 'forecast_period.dart';
import 'timeline_statistics.dart';
import 'welford_calculation.dart';

class AnimatedTimeline extends Equatable {
  final String timelineType; // 'weekly' or 'monthly'
  final List<CashFlowPeriod> historicalPeriods;
  final List<ForecastPeriod> forecastPeriods;
  final TimelineStatistics statistics;
  final WelfordCalculation? welfordStats;
  final int animationDurationMs;
  final bool highlightLeanPeriods;
  final int userId;
  final DateTime generatedAt;
  final int periodCount;

  const AnimatedTimeline({
    required this.timelineType,
    required this.historicalPeriods,
    required this.forecastPeriods,
    required this.statistics,
    this.welfordStats,
    this.animationDurationMs = 2000,
    this.highlightLeanPeriods = true,
    required this.userId,
    required this.generatedAt,
    required this.periodCount,
  });

  @override
  List<Object?> get props => [
        timelineType,
        historicalPeriods,
        forecastPeriods,
        statistics,
        welfordStats,
        animationDurationMs,
        highlightLeanPeriods,
        userId,
        generatedAt,
        periodCount,
      ];
}

