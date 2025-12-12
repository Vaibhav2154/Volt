import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/gamification_feed_model.dart';
import '../models/gamification_profile_model.dart';

abstract class GamificationRemoteDataSource {
  Future<GamificationProfileModel> getProfile({
    required String token,
  });

  Future<GamificationFeedModel> getFeed({
    required String token,
    int limit = 20,
  });
}

class GamificationRemoteDataSourceImpl implements GamificationRemoteDataSource {
  final Dio dio;

  GamificationRemoteDataSourceImpl(this.dio);

  @override
  Future<GamificationProfileModel> getProfile({
    required String token,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.gamificationProfileEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return GamificationProfileModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to load gamification profile');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Not authenticated');
      } else if (e.response?.statusCode == 404) {
        throw NotFoundException('Profile not found');
      } else {
        throw ServerException(e.message ?? 'Failed to load gamification profile');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException || e is NotFoundException) {
        rethrow;
      }
      throw ServerException('An unexpected error occurred');
    }
  }

  @override
  Future<GamificationFeedModel> getFeed({
    required String token,
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.gamificationFeedEndpoint,
        queryParameters: {'limit': limit},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return GamificationFeedModel.fromJson(response.data);
      } else {
        throw ServerException('Failed to load gamification feed');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Not authenticated');
      } else {
        throw ServerException(e.message ?? 'Failed to load gamification feed');
      }
    } catch (e) {
      if (e is ServerException || e is UnauthorizedException) {
        rethrow;
      }
      throw ServerException('An unexpected error occurred');
    }
  }
}

