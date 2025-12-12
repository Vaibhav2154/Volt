import '../../domain/entities/streak.dart';

class StreakModel extends Streak {
  const StreakModel({
    required super.type,
    required super.count,
    required super.lastDate,
    super.nextBonusIn,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      type: json['type'] as String,
      count: json['count'] as int,
      lastDate: json['last_date'] as String,
      nextBonusIn: json['next_bonus_in'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'count': count,
      'last_date': lastDate,
      'next_bonus_in': nextBonusIn,
    };
  }
}

