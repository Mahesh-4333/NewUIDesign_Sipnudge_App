class HydrationDaySummary {
  final int? id;
  final DateTime date; // normalized to local midnight (start of day)
  final int dayIndex; // 0..29 (optional but handy)
  final double target; // ml
  final double consumed; // ml
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
      'date':
          date.millisecondsSinceEpoch, // store epoch millis for local midnight
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
    return HydrationDaySummary(
      id: m['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int).toLocal(),
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
