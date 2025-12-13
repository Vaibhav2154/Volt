import 'package:equatable/equatable.dart';

class HealthScoreTrend extends Equatable {
  final DateTime date;
  final double score;
  final double? change;

  const HealthScoreTrend({
    required this.date,
    required this.score,
    this.change,
  });

  @override
  List<Object?> get props => [date, score, change];
}

