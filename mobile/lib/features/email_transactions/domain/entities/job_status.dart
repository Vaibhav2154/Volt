import 'package:equatable/equatable.dart';

class JobStatus extends Equatable {
  final String jobId;
  final String jobType;
  final String status;
  final String createdAt;
  final String? startedAt;
  final String? completedAt;
  final String? failedAt;
  final int attempts;
  final String? lastError;

  const JobStatus({
    required this.jobId,
    required this.jobType,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.failedAt,
    required this.attempts,
    this.lastError,
  });

  @override
  List<Object?> get props => [
        jobId,
        jobType,
        status,
        createdAt,
        startedAt,
        completedAt,
        failedAt,
        attempts,
        lastError,
      ];
}





