import '../../domain/entities/job_stats.dart';

class JobStatsModel extends JobStats {
  const JobStatsModel({
    required super.queued,
    required super.processing,
    required super.failed,
  });

  factory JobStatsModel.fromJson(Map<String, dynamic> json) {
    return JobStatsModel(
      queued: json['queued'] as int? ?? 0,
      processing: json['processing'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queued': queued,
      'processing': processing,
      'failed': failed,
    };
  }
}






