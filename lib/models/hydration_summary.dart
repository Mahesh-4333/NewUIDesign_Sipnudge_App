class HydrationDaySummary {
  final int? id;
  final DateTime date;
  final int dayIndex;
  final double target;
  final double consumed;
  final String? deviceId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPerfect;

  HydrationDaySummary({
    this.id,
    required this.date,
    required this.dayIndex,
    required this.target,
    required this.consumed,
    this.deviceId,
    DateTime? createdAt,
    this.isPerfect = false,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'day_index': dayIndex,
      'target': target,
      'consumed': consumed,
      'device_id': deviceId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'is_perfect': isPerfect ? 1 : 0,
    };
  }

  factory HydrationDaySummary.fromMap(Map<String, dynamic> m) {
    DateTime parsedDate;
    var rawDate = m['date'];
    if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate).toLocal();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0).toLocal();
    } else {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(0).toLocal();
    }

    return HydrationDaySummary(
      id: m['id'] as int?,
      date: parsedDate,
      dayIndex: (m['day_index'] as int?) ?? 0,
      target: (m['target'] as num).toDouble(),
      consumed: (m['consumed'] as num).toDouble(),
      deviceId: m['device_id'] as String?,
      isPerfect: (m['is_perfect'] as int? ?? 0) == 1,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int).toLocal(),
      updatedAt: m['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(m['updated_at'] as int)
              .toLocal()
          : null,
    );
  }
}
