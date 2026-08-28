class DeviceOtherData {
  final String? version;
  final int? hwVersion;
  final int? programmedAt;
  final List<DeviceSlotSchedule> slots;
  final String rawData;

  const DeviceOtherData({
    this.version,
    this.hwVersion,
    this.programmedAt,
    this.slots = const [],
    this.rawData = '',
  });

  factory DeviceOtherData.fromJson(Map<String, dynamic> json, {String rawData = ''}) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    final parsedSlots = rawSlots
        .whereType<Map<String, dynamic>>()
        .map((s) => DeviceSlotSchedule.fromJson(s))
        .toList();

    return DeviceOtherData(
      version: json['version']?.toString(),
      hwVersion: json['hwVersion'] is int
          ? json['hwVersion'] as int
          : int.tryParse(json['hwVersion']?.toString() ?? ''),
      programmedAt: json['programmedAt'] is int
          ? json['programmedAt'] as int
          : int.tryParse(json['programmedAt']?.toString() ?? ''),
      slots: parsedSlots,
      rawData: rawData,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'hwVersion': hwVersion,
        'programmedAt': programmedAt,
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  DateTime? get programmedAtDateTime =>
      (programmedAt != null && programmedAt! > 0)
          ? DateTime.fromMillisecondsSinceEpoch(programmedAt! * 1000, isUtc: true).toLocal()
          : null;
}

class DeviceSlotSchedule {
  final int index;
  final String name;
  final int start;
  final int end;

  const DeviceSlotSchedule({
    required this.index,
    required this.name,
    required this.start,
    required this.end,
  });

  factory DeviceSlotSchedule.fromJson(Map<String, dynamic> json) {
    return DeviceSlotSchedule(
      index: json['i'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'i': index,
        'name': name,
        'start': start,
        'end': end,
      };

  DateTime? get startDateTime =>
      start > 0 ? DateTime.fromMillisecondsSinceEpoch(start * 1000, isUtc: true).toLocal() : null;

  DateTime? get endDateTime =>
      end > 0 ? DateTime.fromMillisecondsSinceEpoch(end * 1000, isUtc: true).toLocal() : null;
}
