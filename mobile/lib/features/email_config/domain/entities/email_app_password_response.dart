import 'package:equatable/equatable.dart';

class EmailAppPasswordResponse extends Equatable {
  final String status;
  final bool emailParsingEnabled;
  final String message;

  const EmailAppPasswordResponse({
    required this.status,
    required this.emailParsingEnabled,
    required this.message,
  });

  @override
  List<Object?> get props => [status, emailParsingEnabled, message];
}





