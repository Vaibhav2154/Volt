class Streak {
  final String type;
  final int count;
  final String lastDate;
  final int? nextBonusIn;

  const Streak({
    required this.type,
    required this.count,
    required this.lastDate,
    this.nextBonusIn,
  });
}

