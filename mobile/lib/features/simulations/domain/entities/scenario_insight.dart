import 'package:equatable/equatable.dart';

class QuickWin extends Equatable {
  final String category;
  final String categoryKey;
  final String action;
  final double monthlyImpact;
  final double annualImpact;
  final String difficulty; // "easy", "moderate", "challenging"
  final double currentSpending;
  final double newSpending;
  final String? reason;

  const QuickWin({
    required this.category,
    required this.categoryKey,
    required this.action,
    required this.monthlyImpact,
    required this.annualImpact,
    required this.difficulty,
    required this.currentSpending,
    required this.newSpending,
    this.reason,
  });

  @override
  List<Object?> get props => [
        category,
        categoryKey,
        action,
        monthlyImpact,
        annualImpact,
        difficulty,
        currentSpending,
        newSpending,
        reason,
      ];
}

class Warning extends Equatable {
  final String type;
  final String message;
  final String severity; // "info", "warning", "error"
  final String? metric;
  final String? recommendation;

  const Warning({
    required this.type,
    required this.message,
    required this.severity,
    this.metric,
    this.recommendation,
  });

  @override
  List<Object?> get props => [type, message, severity, metric, recommendation];
}

class ScenarioInsight extends Equatable {
  final String headline;
  final String confidence; // "high", "moderate", "low"
  final String confidenceReason;
  final List<QuickWin> quickWins;
  final List<Warning> warnings;
  final String timeline;
  final String visualSuggestion;
  final String annualImpact;
  final double annualImpactValue;
  final int achievabilityScore;
  final int totalCategoriesAffected;

  const ScenarioInsight({
    required this.headline,
    required this.confidence,
    required this.confidenceReason,
    required this.quickWins,
    required this.warnings,
    required this.timeline,
    required this.visualSuggestion,
    required this.annualImpact,
    required this.annualImpactValue,
    required this.achievabilityScore,
    required this.totalCategoriesAffected,
  });

  @override
  List<Object?> get props => [
        headline,
        confidence,
        confidenceReason,
        quickWins,
        warnings,
        timeline,
        visualSuggestion,
        annualImpact,
        annualImpactValue,
        achievabilityScore,
        totalCategoriesAffected,
      ];
}





