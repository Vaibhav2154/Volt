import '../../domain/entities/risk_summary.dart';

class RiskSummaryModel extends RiskSummary {
  const RiskSummaryModel({
    required super.riskLevel,
    required super.riskMessage,
    required super.immediateActionNeeded,
  });

  factory RiskSummaryModel.fromJson(Map<String, dynamic> json) {
    return RiskSummaryModel(
      riskLevel: json['risk_level'] as String? ?? 'UNKNOWN',
      riskMessage: json['risk_message'] as String? ?? '',
      immediateActionNeeded: json['immediate_action_needed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_level': riskLevel,
      'risk_message': riskMessage,
      'immediate_action_needed': immediateActionNeeded,
    };
  }
}






