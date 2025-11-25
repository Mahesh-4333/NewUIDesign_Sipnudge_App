import 'dart:math';

class BottleData {
  final double liquidVolume;
  final int liquidPercent;
  final int battery;
  final DateTime timestamp;

  BottleData({
    required this.liquidVolume,
    required this.liquidPercent,
    required this.battery,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'liquidVolume': liquidVolume,
      'liquidPercent': liquidPercent,
      'battery': battery,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BottleData.fromMap(Map<String, dynamic> map) {
    return BottleData(
      liquidVolume: map['liquidVolume'] as double,
      liquidPercent: map['liquidPercent'] as int,
      battery: map['battery'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

List<BottleData> generateDummyWeeklyData() {
  final now = DateTime.now();
  final random = Random();

  return List.generate(7, (index) {
    final date = now.subtract(Duration(days: 6 - index));
    return BottleData(
      liquidVolume: random.nextDouble() * 1000, // ml (0–1000ml)
      liquidPercent: random.nextInt(101), // 0–100%
      battery: 50 + random.nextInt(51), // 50–100%
      timestamp: date,
    );
  });
}

List<BottleData> generateDummyMonthlyData() {
  final now = DateTime.now();
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final random = Random();

  return List.generate(daysInMonth, (index) {
    final date = DateTime(now.year, now.month, index + 1);
    return BottleData(
      liquidVolume: random.nextDouble() * 1000,
      liquidPercent: random.nextInt(101),
      battery: 40 + random.nextInt(61),
      timestamp: date,
    );
  });
}
