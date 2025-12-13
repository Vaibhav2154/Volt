import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/cash_flow_forecast_model.dart';
import '../models/income_smoothing_recommendation_model.dart';
import '../models/lean_week_analysis_model.dart';

abstract class LeanWeekRemoteDataSource {
  Future<LeanWeekAnalysisModel> getLeanWeekAnalysis({
    required String token,
    double? currentBalance,
  });

  Future<CashFlowForecastModel> getCashFlowForecast({
    required String token,
    int periods = 3,
    double? currentBalance,
  });

  Future<IncomeSmoothingRecommendationModel>
      getIncomeSmoothingRecommendations({
    required String token,
    double? currentBalance,
    int targetMonths = 3,
  });
}

class LeanWeekRemoteDataSourceImpl implements LeanWeekRemoteDataSource {
  final Dio dio;

  LeanWeekRemoteDataSourceImpl(this.dio);

  @override
  Future<LeanWeekAnalysisModel> getLeanWeekAnalysis({
    required String token,
    double? currentBalance,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (currentBalance != null) {
        queryParams['current_balance'] = currentBalance;
      }

      final response = await dio.get(
        ApiConstants.leanWeekAnalysisEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return LeanWeekAnalysisModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to get lean week analysis');
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
  Future<CashFlowForecastModel> getCashFlowForecast({
    required String token,
    int periods = 3,
    double? currentBalance,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'periods': periods,
      };
      if (currentBalance != null) {
        queryParams['current_balance'] = currentBalance;
      }

      final response = await dio.get(
        ApiConstants.leanWeekForecastEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return CashFlowForecastModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to get cash flow forecast');
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
  Future<IncomeSmoothingRecommendationModel>
      getIncomeSmoothingRecommendations({
    required String token,
    double? currentBalance,
    int targetMonths = 3,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'target_months': targetMonths,
      };
      if (currentBalance != null) {
        queryParams['current_balance'] = currentBalance;
      }

      final response = await dio.get(
        ApiConstants.leanWeekSmoothingRecommendationsEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return IncomeSmoothingRecommendationModel.fromJson(response.data);
      } else {
        throw const ServerException(
            'Failed to get income smoothing recommendations');
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
}






