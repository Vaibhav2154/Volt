import 'package:equatable/equatable.dart';

class EmailParsingStatus extends Equatable {
  final bool emailParsingEnabled;
  final String? emailAddress;
  final bool hasAppPassword;
  final String message;

  const EmailParsingStatus({
    required this.emailParsingEnabled,
    this.emailAddress,
    required this.hasAppPassword,
    required this.message,
  });

  @override
  List<Object?> get props => [
        emailParsingEnabled,
        emailAddress,
        hasAppPassword,
        message,
      ];
}







