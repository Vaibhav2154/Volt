import '../../domain/entities/manual_email_job_response.dart';

class ManualEmailJobResponseModel extends ManualEmailJobResponse {
  const ManualEmailJobResponseModel({
    required super.message,
    required super.jobId,
    super.transactionPreview,
  });

  factory ManualEmailJobResponseModel.fromJson(Map<String, dynamic> json) {
    TransactionPreview? preview;
    if (json['transaction_preview'] != null) {
      final previewData = json['transaction_preview'] as Map<String, dynamic>;
      preview = TransactionPreview(
        amount: previewData['amount'] != null
            ? (previewData['amount'] as num).toDouble()
            : null,
        merchant: previewData['merchant'] as String?,
        type: previewData['type'] as String?,
        bank: previewData['bank'] as String?,
      );
    }

    return ManualEmailJobResponseModel(
      message: json['message'] as String,
      jobId: json['job_id'] as String,
      transactionPreview: preview,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'job_id': jobId,
      'transaction_preview': transactionPreview != null
          ? {
              'amount': transactionPreview!.amount,
              'merchant': transactionPreview!.merchant,
              'type': transactionPreview!.type,
              'bank': transactionPreview!.bank,
            }
          : null,
    };
  }
}





