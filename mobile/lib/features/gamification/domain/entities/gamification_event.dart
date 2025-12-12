class GamificationEvent {
  final int id;
  final String eventType;
  final int xpAwarded;
  final String? message;
  final DateTime createdAt;

  const GamificationEvent({
    required this.id,
    required this.eventType,
    required this.xpAwarded,
    this.message,
    required this.createdAt,
  });
}

