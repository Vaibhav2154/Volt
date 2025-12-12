import 'package:equatable/equatable.dart';

class JobStats extends Equatable {
  final int queued;
  final int processing;
  final int failed;

  const JobStats({
    required this.queued,
    required this.processing,
    required this.failed,
  });

  @override
  List<Object?> get props => [queued, processing, failed];
}





