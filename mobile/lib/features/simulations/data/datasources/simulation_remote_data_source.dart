import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/projection_response_model.dart';
import '../models/reallocation_response_model.dart';
import '../models/scenario_comparison_model.dart';
import '../models/scenario_insight_model.dart';
import '../models/simulation_response_model.dart';

abstract class SimulationRemoteDataSource {
  Future<SimulationResponseModel> simulateSpending({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  });

  Future<ScenarioInsightModel> simulateSpendingEnhanced({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  });

  Future<ScenarioComparisonResponseModel> compareScenarios({
    required String token,
    required int userId,
    required String scenarioType,
    int timePeriodDays = 30,
    int numScenarios = 3,
  });

  Future<ReallocationResponseModel> simulateReallocation({
    required String token,
    required int userId,
    required Map<String, double> reallocations,
    int timePeriodDays = 30,
  });

  Future<ProjectionResponseModel> projectFutureSpending({
    required String token,
    required int userId,
    required int projectionMonths,
    int timePeriodDays = 30,
    String? scenarioId,
    Map<String, double>? behavioralChanges,
  });
}

class SimulationRemoteDataSourceImpl implements SimulationRemoteDataSource {
  final Dio dio;

  SimulationRemoteDataSourceImpl(this.dio);

  @override
  Future<SimulationResponseModel> simulateSpending({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.simulationEndpoint(userId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          'scenario_type': scenarioType,
          'target_percent': targetPercent,
          'time_period_days': timePeriodDays,
          if (targetCategories != null) 'target_categories': targetCategories,
        },
      );

      if (response.statusCode == 200) {
        return SimulationResponseModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to simulate spending');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      }
      if (e.response?.statusCode == 404) {
        throw const NotFoundException('User or behavior model not found');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to parse response: ${e.toString()}');
    }
  }

  @override
  Future<ScenarioInsightModel> simulateSpendingEnhanced({
    required String token,
    required int userId,
    required String scenarioType,
    required double targetPercent,
    int timePeriodDays = 30,
    List<String>? targetCategories,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.simulationEnhancedEndpoint(userId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          'scenario_type': scenarioType,
          'target_percent': targetPercent,
          'time_period_days': timePeriodDays,
          if (targetCategories != null) 'target_categories': targetCategories,
        },
      );

      if (response.statusCode == 200) {
        return ScenarioInsightModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to simulate spending');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      }
      if (e.response?.statusCode == 404) {
        throw const NotFoundException('User or behavior model not found');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to parse response: ${e.toString()}');
    }
  }

  @override
  Future<ScenarioComparisonResponseModel> compareScenarios({
    required String token,
    required int userId,
    required String scenarioType,
    int timePeriodDays = 30,
    int numScenarios = 3,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.simulationCompareEndpoint(userId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          'scenario_type': scenarioType,
          'time_period_days': timePeriodDays,
          'num_scenarios': numScenarios,
        },
      );

      if (response.statusCode == 200) {
        return ScenarioComparisonResponseModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to compare scenarios');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      }
      if (e.response?.statusCode == 404) {
        throw const NotFoundException('User or behavior model not found');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to parse response: ${e.toString()}');
    }
  }

  @override
  Future<ReallocationResponseModel> simulateReallocation({
    required String token,
    required int userId,
    required Map<String, double> reallocations,
    int timePeriodDays = 30,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.simulationReallocateEndpoint(userId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          'reallocations': reallocations,
          'time_period_days': timePeriodDays,
        },
      );

      if (response.statusCode == 200) {
        return ReallocationResponseModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to simulate reallocation');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      }
      if (e.response?.statusCode == 404) {
        throw const NotFoundException('User or behavior model not found');
      }
      if (e.response?.statusCode == 400) {
        throw ServerException(e.response?.data['detail'] ?? 'Invalid reallocation request');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to parse response: ${e.toString()}');
    }
  }

  @override
  Future<ProjectionResponseModel> projectFutureSpending({
    required String token,
    required int userId,
    required int projectionMonths,
    int timePeriodDays = 30,
    String? scenarioId,
    Map<String, double>? behavioralChanges,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.simulationProjectEndpoint(userId),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: {
          'projection_months': projectionMonths,
          'time_period_days': timePeriodDays,
          if (scenarioId != null) 'scenario_id': scenarioId,
          if (behavioralChanges != null) 'behavioral_changes': behavioralChanges,
        },
      );

      if (response.statusCode == 200) {
        return ProjectionResponseModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to project future spending');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Invalid or expired token');
      }
      if (e.response?.statusCode == 404) {
        throw const NotFoundException('User or behavior model not found');
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('Failed to parse response: ${e.toString()}');
    }
  }
}

