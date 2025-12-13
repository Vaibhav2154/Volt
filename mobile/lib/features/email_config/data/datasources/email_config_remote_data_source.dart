import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/email_app_password_response_model.dart';
import '../models/email_parsing_status_model.dart';

abstract class EmailConfigRemoteDataSource {
  Future<EmailAppPasswordResponseModel> setupAppPassword({
    required String appPassword,
    required bool consent,
    required String token,
  });

  Future<EmailParsingStatusModel> getEmailParsingStatus({
    required String token,
  });

  Future<EmailAppPasswordResponseModel> disableEmailParsing({
    required bool confirm,
    required String token,
  });

  Future<EmailAppPasswordResponseModel> updateAppPassword({
    required String appPassword,
    required bool consent,
    required String token,
  });
}

class EmailConfigRemoteDataSourceImpl implements EmailConfigRemoteDataSource {
  final Dio dio;

  EmailConfigRemoteDataSourceImpl(this.dio);

  @override
  Future<EmailAppPasswordResponseModel> setupAppPassword({
    required String appPassword,
    required bool consent,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.emailConfigSetupAppPasswordEndpoint,
        data: {
          'app_password': appPassword,
          'consent': consent,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return EmailAppPasswordResponseModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to setup app password');
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
  Future<EmailParsingStatusModel> getEmailParsingStatus({
    required String token,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.emailConfigStatusEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return EmailParsingStatusModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to get email parsing status');
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
  Future<EmailAppPasswordResponseModel> disableEmailParsing({
    required bool confirm,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.emailConfigDisableEndpoint,
        data: {
          'confirm': confirm,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return EmailAppPasswordResponseModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to disable email parsing');
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
  Future<EmailAppPasswordResponseModel> updateAppPassword({
    required String appPassword,
    required bool consent,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.emailConfigUpdateAppPasswordEndpoint,
        data: {
          'app_password': appPassword,
          'consent': consent,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return EmailAppPasswordResponseModel.fromJson(response.data);
      } else {
        throw const ServerException('Failed to update app password');
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
}







