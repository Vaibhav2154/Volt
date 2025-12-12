import '../../domain/entities/gamification_event.dart';

class GamificationEventModel extends GamificationEvent {
  const GamificationEventModel({
    required super.id,
    required super.eventType,
    required super.xpAwarded,
    super.message,
    required super.createdAt,
  });

  factory GamificationEventModel.fromJson(Map<String, dynamic> json) {
    return GamificationEventModel(
      id: json['id'] as int,
      eventType: json['event_type'] as String,
      xpAwarded: json['xp_awarded'] as int,
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'xp_awarded': xpAwarded,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

