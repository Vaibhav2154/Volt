import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../models/email_health_status_model.dart';
import '../models/job_stats_model.dart';
import '../models/job_status_model.dart';
import '../models/manual_email_job_response_model.dart';

abstract class EmailTransactionsRemoteDataSource {
  Future<JobStatsModel> getQueueStats({
    required String token,
  });

  Future<JobStatusModel> getJobStatus({
    required String jobId,
    required String token,
  });

  Future<ManualEmailJobResponseModel> enqueueManualEmail({
    required String sender,
    required String subject,
    required String body,
    required String token,
  });

  Future<List<TransactionModel>> getRecentTransactions({
    required String token,
    int limit = 20,
  });

  Future<List<TransactionModel>> getTransactionsByBank({
    required String bankName,
    required String token,
    int limit = 20,
  });

  Future<EmailHealthStatusModel> getHealthStatus({
    required String token,
  });
}

class EmailTransactionsRemoteDataSourceImpl
    implements EmailTransactionsRemoteDataSource {
  final Dio dio;

  EmailTransactionsRemoteDataSourceImpl(this.dio);

  @override
  Future<JobStatsModel> getQueueStats({
    required String token,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.emailTransactionsQueueStatsEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return JobStatsModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to get queue stats');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw const ServerException('An unexpected error occurred');
    }
  }

  @override
  Future<JobStatusModel> getJobStatus({
    required String jobId,
    required String token,
  }) async {
    try {
      final response = await dio.get(
        '${ApiConstants.emailTransactionsQueueJobEndpoint}/$jobId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return JobStatusModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to get job status');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      } else if (e.response?.statusCode == 404) {
        throw const ServerException('Job not found');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw const ServerException('An unexpected error occurred');
    }
  }

  @override
  Future<ManualEmailJobResponseModel> enqueueManualEmail({
    required String sender,
    required String subject,
    required String body,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.emailTransactionsQueueManualEndpoint,
        data: {
          'sender': sender,
          'subject': subject,
          'body': body,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ManualEmailJobResponseModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to enqueue manual email');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      } else if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['detail'] ?? 'Invalid request';
        throw ServerException(errorMessage);
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw const ServerException('An unexpected error occurred');
    }
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions({
    required String token,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.emailTransactionsRecentEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: {
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      } else {
        throw const ServerException('Failed to get recent transactions');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw const ServerException('An unexpected error occurred');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactionsByBank({
    required String bankName,
    required String token,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '${ApiConstants.emailTransactionsByBankEndpoint}/$bankName',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: {
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      } else {
        throw const ServerException('Failed to get transactions by bank');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw const ServerException('An unexpected error occurred');
    }
  }

  @override
  Future<EmailHealthStatusModel> getHealthStatus({
    required String token,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.emailTransactionsHealthEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return EmailHealthStatusModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to get health status');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      } else if (e.response?.statusCode == 503) {
        throw ServerException(
          e.response?.data['detail'] ?? 'Service unavailable',
        );
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      throw const ServerException('An unexpected error occurred');
    }
  }
}

