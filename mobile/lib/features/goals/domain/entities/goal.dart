import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime endDate;
  final bool isActive;
  final bool isAchieved;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.endDate,
    required this.isActive,
    required this.isAchieved,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        targetAmount,
        currentAmount,
        endDate,
        isActive,
        isAchieved,
        createdAt,
        updatedAt,
      ];
}







