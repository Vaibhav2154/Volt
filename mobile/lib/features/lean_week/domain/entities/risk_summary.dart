import 'package:equatable/equatable.dart';

class RiskSummary extends Equatable {
  final String riskLevel;
  final String riskMessage;
  final bool immediateActionNeeded;

  const RiskSummary({
    required this.riskLevel,
    required this.riskMessage,
    required this.immediateActionNeeded,
  });

  @override
  List<Object?> get props => [riskLevel, riskMessage, immediateActionNeeded];
}







