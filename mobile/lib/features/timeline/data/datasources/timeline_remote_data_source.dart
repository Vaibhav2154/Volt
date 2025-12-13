import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/animated_timeline_model.dart';

abstract class TimelineRemoteDataSource {
  Future<AnimatedTimelineModel> getAnimatedTimeline({
    required String token,
    required int userId,
    String timelineType = 'monthly',
    int periods = 12,
    bool includeForecast = true,
  });
}

class TimelineRemoteDataSourceImpl implements TimelineRemoteDataSource {
  final Dio dio;

  TimelineRemoteDataSourceImpl(this.dio);

  @override
  Future<AnimatedTimelineModel> getAnimatedTimeline({
    required String token,
    required int userId,
    String timelineType = 'monthly',
    int periods = 12,
    bool includeForecast = true,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.animatedTimelineEndpoint(userId),
        queryParameters: {
          'timeline_type': timelineType,
          'periods': periods,
          'include_forecast': includeForecast,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return AnimatedTimelineModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to load timeline');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const UnauthorizedException('Not authenticated');
      } else if (e.response?.statusCode == 404) {
        throw const NotFoundException('Not enough transaction data');
      } else {
        throw ServerException(e.message ?? 'Failed to load timeline');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NotFoundException) {
        rethrow;
      }
      throw const ServerException('An unexpected error occurred');
    }
  }
}

