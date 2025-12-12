import 'package:equatable/equatable.dart';
import 'lean_analysis.dart';

class HistoricalAnalysis extends Equatable {
  final LeanAnalysis monthly;
  final LeanAnalysis weekly;

  const HistoricalAnalysis({
    required this.monthly,
    required this.weekly,
  });

  @override
  List<Object?> get props => [monthly, weekly];
}





