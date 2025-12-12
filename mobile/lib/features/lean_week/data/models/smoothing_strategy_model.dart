import '../../domain/entities/smoothing_strategy.dart';

class SmoothingStrategyModel extends SmoothingStrategy {
  const SmoothingStrategyModel({
    required super.volatilityLevel,
    required super.strategySummary,
    required super.leanFrequency,
    required super.recommendations,
    required super.actionItems,
  });

  factory SmoothingStrategyModel.fromJson(Map<String, dynamic> json) {
    return SmoothingStrategyModel(
      volatilityLevel: json['volatility_level'] as String? ?? 'unknown',
      strategySummary: json['strategy_summary'] as String? ?? '',
      leanFrequency: (json['lean_frequency'] as num?)?.toDouble() ?? 0.0,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      actionItems: (json['action_items'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volatility_level': volatilityLevel,
      'strategy_summary': strategySummary,
      'lean_frequency': leanFrequency,
      'recommendations': recommendations,
      'action_items': actionItems,
    };
  }
}





