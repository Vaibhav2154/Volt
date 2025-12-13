import '../../domain/entities/job_status.dart';

class JobStatusModel extends JobStatus {
  const JobStatusModel({
    required super.jobId,
    required super.jobType,
    required super.status,
    required super.createdAt,
    super.startedAt,
    super.completedAt,
    super.failedAt,
    required super.attempts,
    super.lastError,
  });

  factory JobStatusModel.fromJson(Map<String, dynamic> json) {
    return JobStatusModel(
      jobId: json['job_id'] as String,
      jobType: json['job_type'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      startedAt: json['started_at'] as String?,
      completedAt: json['completed_at'] as String?,
      failedAt: json['failed_at'] as String?,
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'job_type': jobType,
      'status': status,
      'created_at': createdAt,
      'started_at': startedAt,
      'completed_at': completedAt,
      'failed_at': failedAt,
      'attempts': attempts,
      'last_error': lastError,
    };
  }
}






