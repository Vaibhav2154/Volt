import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/financial_health_score_model.dart';

abstract class HealthScoreRemoteDataSource {
  Future<FinancialHealthScoreModel> getHealthScore({
    required String token,
    required int userId,
  });
}

class HealthScoreRemoteDataSourceImpl implements HealthScoreRemoteDataSource {
  final Dio dio;

  HealthScoreRemoteDataSourceImpl(this.dio);

  @override
  Future<FinancialHealthScoreModel> getHealthScore({
    required String token,
    required int userId,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.healthScoreEndpoint(userId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return FinancialHealthScoreModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to load health score');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Not authenticated');
      } else if (e.response?.statusCode == 404) {
        throw const NotFoundException('Not enough transaction data');
      } else {
        throw ServerException(e.message ?? 'Failed to load health score');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NotFoundException) {
        rethrow;
      }
      throw const ServerException('An unexpected error occurred');
    }
  }
}

