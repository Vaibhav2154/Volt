import '../../domain/entities/timeline_statistics.dart';

class TimelineStatisticsModel extends TimelineStatistics {
  const TimelineStatisticsModel({
    required super.totalIncome,
    required super.totalExpenses,
    required super.totalNetFlow,
    required super.avgNetFlow,
    required super.leanPeriodCount,
    required super.leanFrequency,
    required super.volatility,
  });

  factory TimelineStatisticsModel.fromJson(Map<String, dynamic> json) {
    return TimelineStatisticsModel(
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      totalNetFlow: (json['total_net_flow'] as num).toDouble(),
      avgNetFlow: (json['avg_net_flow'] as num).toDouble(),
      leanPeriodCount: json['lean_period_count'] as int,
      leanFrequency: (json['lean_frequency'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
    );
  }
}

