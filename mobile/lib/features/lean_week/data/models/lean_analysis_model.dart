import '../../domain/entities/lean_analysis.dart';
import 'lean_period_model.dart';

class LeanPatternModel extends LeanPattern {
  const LeanPatternModel({
    required super.hasPattern,
    super.patternType,
    required super.description,
  });

  factory LeanPatternModel.fromJson(Map<String, dynamic> json) {
    return LeanPatternModel(
      hasPattern: json['has_pattern'] as bool? ?? false,
      patternType: json['pattern_type'] as String?,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_pattern': hasPattern,
      'pattern_type': patternType,
      'description': description,
    };
  }
}

class LeanAnalysisModel extends LeanAnalysis {
  const LeanAnalysisModel({
    required super.leanPeriods,
    required super.leanFrequency,
    required super.avgLeanSeverity,
    required super.patternDetected,
    required super.threshold,
  });

  factory LeanAnalysisModel.fromJson(Map<String, dynamic> json) {
    return LeanAnalysisModel(
      leanPeriods: (json['lean_periods'] as List<dynamic>?)
              ?.map((e) => LeanPeriodModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      leanFrequency: (json['lean_frequency'] as num?)?.toDouble() ?? 0.0,
      avgLeanSeverity: (json['avg_lean_severity'] as num?)?.toDouble() ?? 0.0,
      patternDetected: LeanPatternModel.fromJson(
        json['pattern_detected'] as Map<String, dynamic>,
      ),
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lean_periods': leanPeriods.map((e) => (e as LeanPeriodModel).toJson()).toList(),
      'lean_frequency': leanFrequency,
      'avg_lean_severity': avgLeanSeverity,
      'pattern_detected': (patternDetected as LeanPatternModel).toJson(),
      'threshold': threshold,
    };
  }
}





