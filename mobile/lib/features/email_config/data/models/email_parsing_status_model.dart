import '../../domain/entities/email_parsing_status.dart';

class EmailParsingStatusModel extends EmailParsingStatus {
  const EmailParsingStatusModel({
    required super.emailParsingEnabled,
    super.emailAddress,
    required super.hasAppPassword,
    required super.message,
  });

  factory EmailParsingStatusModel.fromJson(Map<String, dynamic> json) {
    return EmailParsingStatusModel(
      emailParsingEnabled: json['email_parsing_enabled'] ?? false,
      emailAddress: json['email_address'],
      hasAppPassword: json['has_app_password'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email_parsing_enabled': emailParsingEnabled,
      'email_address': emailAddress,
      'has_app_password': hasAppPassword,
      'message': message,
    };
  }
}

