import '../../domain/entities/email_health_status.dart';
import 'job_stats_model.dart';

class EmailHealthStatusModel extends EmailHealthStatus {
  const EmailHealthStatusModel({
    required super.status,
    required super.redisConnected,
    required super.queueStats,
    required super.timestamp,
  });

  factory EmailHealthStatusModel.fromJson(Map<String, dynamic> json) {
    return EmailHealthStatusModel(
      status: json['status'] as String,
      redisConnected: json['redis_connected'] as bool? ?? false,
      queueStats: JobStatsModel.fromJson(
        json['queue_stats'] as Map<String, dynamic>,
      ),
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'redis_connected': redisConnected,
      'queue_stats': (queueStats as JobStatsModel).toJson(),
      'timestamp': timestamp,
    };
  }
}







