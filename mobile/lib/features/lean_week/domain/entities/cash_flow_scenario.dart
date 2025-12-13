import 'package:equatable/equatable.dart';

class CashFlowScenario extends Equatable {
  final double best;
  final double likely;
  final double worst;

  const CashFlowScenario({
    required this.best,
    required this.likely,
    required this.worst,
  });

  @override
  List<Object?> get props => [best, likely, worst];
}







