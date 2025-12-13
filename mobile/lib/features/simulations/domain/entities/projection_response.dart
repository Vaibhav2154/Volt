import 'package:equatable/equatable.dart';

class MonthlyProjection extends Equatable {
  final int month;
  final String monthLabel;
  final double projectedSpending;
  final Map<String, double> categoryBreakdown;
  final double cumulativeChange;
  final double confidence;

  const MonthlyProjection({
    required this.month,
    required this.monthLabel,
    required this.projectedSpending,
    required this.categoryBreakdown,
    required this.cumulativeChange,
    required this.confidence,
  });

  @override
  List<Object?> get props => [
        month,
        monthLabel,
        projectedSpending,
        categoryBreakdown,
        cumulativeChange,
        confidence,
      ];
}

class ProjectionResponse extends Equatable {
  final double baselineMonthly;
  final int projectionMonths;
  final List<MonthlyProjection> monthlyProjections;
  final double totalProjected;
  final double totalBaseline;
  final double cumulativeChange;
  final double annualImpact;
  final String trendAnalysis;
  final String confidenceLevel;
  final List<String> keyInsights;
  final Map<String, dynamic> projectionChart;

  const ProjectionResponse({
    required this.baselineMonthly,
    required this.projectionMonths,
    required this.monthlyProjections,
    required this.totalProjected,
    required this.totalBaseline,
    required this.cumulativeChange,
    required this.annualImpact,
    required this.trendAnalysis,
    required this.confidenceLevel,
    required this.keyInsights,
    required this.projectionChart,
  });

  @override
  List<Object?> get props => [
        baselineMonthly,
        projectionMonths,
        monthlyProjections,
        totalProjected,
        totalBaseline,
        cumulativeChange,
        annualImpact,
        trendAnalysis,
        confidenceLevel,
        keyInsights,
        projectionChart,
      ];
}







