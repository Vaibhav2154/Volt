import 'package:equatable/equatable.dart';
import 'job_stats.dart';

class EmailHealthStatus extends Equatable {
  final String status;
  final bool redisConnected;
  final JobStats queueStats;
  final String timestamp;

  const EmailHealthStatus({
    required this.status,
    required this.redisConnected,
    required this.queueStats,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [status, redisConnected, queueStats, timestamp];
}







