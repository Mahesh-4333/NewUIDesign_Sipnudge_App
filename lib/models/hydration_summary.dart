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

  HydrationDaySummary copyWith({
    int? id,
    DateTime? date,
    int? dayIndex,
    double? target,
    double? consumed,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPerfect,
  }) {
    return HydrationDaySummary(
      id: id ?? this.id,
      date: date ?? this.date,
      dayIndex: dayIndex ?? this.dayIndex,
      target: target ?? this.target,
      consumed: consumed ?? this.consumed,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPerfect: isPerfect ?? this.isPerfect,
    );
  }

  factory HydrationDaySummary.fromMap(Map<String, dynamic> m) {
    // Robust parsing for 'date' which might be stored as String or int
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

  /// Parses the camelCase JSON shape returned by the backend
  /// `GET /api/database/daily-summaries/:userId` endpoint.
  factory HydrationDaySummary.fromServerMap(Map<String, dynamic> m) {
    DateTime parsedDate;
    final rawDate = m['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0).toLocal();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate).toLocal();
    } else {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(0).toLocal();
    }

    DateTime? parseIso(dynamic raw) {
      if (raw == null) return null;
      if (raw is String) return DateTime.tryParse(raw)?.toLocal();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw).toLocal();
      return null;
    }

    return HydrationDaySummary(
      date: parsedDate,
      dayIndex: (m['dayIndex'] as int?) ?? 0,
      target: (m['target'] as num).toDouble(),
      consumed: (m['consumed'] as num).toDouble(),
      isPerfect: (m['isPerfect'] as bool?) ?? false,
      deviceId: m['deviceId'] as String?,
      createdAt: parseIso(m['createdAt']) ?? DateTime.now(),
      updatedAt: parseIso(m['updatedAt']),
    );
  }
}

