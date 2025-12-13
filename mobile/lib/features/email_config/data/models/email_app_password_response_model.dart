import '../../domain/entities/email_app_password_response.dart';

class EmailAppPasswordResponseModel extends EmailAppPasswordResponse {
  const EmailAppPasswordResponseModel({
    required super.status,
    required super.emailParsingEnabled,
    required super.message,
  });

  factory EmailAppPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return EmailAppPasswordResponseModel(
      status: json['status'] ?? '',
      emailParsingEnabled: json['email_parsing_enabled'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'email_parsing_enabled': emailParsingEnabled,
      'message': message,
    };
  }
}







