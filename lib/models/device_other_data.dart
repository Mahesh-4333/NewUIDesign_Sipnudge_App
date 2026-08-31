import 'dart:convert';
import 'package:intl/intl.dart';

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
    dynamic rawSlots = json['slots'] ?? json['s'] ?? json['slot_schedules'] ?? json['slotSchedules'] ?? json['schedules'];
    if (rawSlots == null) {
      for (final entry in json.entries) {
        final k = entry.key.toLowerCase();
        if (k.contains('slot') || k.contains('sched')) {
          rawSlots = entry.value;
          break;
        }
      }
    }
    if (rawSlots is String && rawSlots.trim().startsWith('[')) {
      try {
        rawSlots = jsonDecode(rawSlots);
      } catch (_) {}
    }
    final List<DeviceSlotSchedule> parsedSlots = [];
    if (rawSlots is List) {
      for (final item in rawSlots) {
        if (item is List) {
          try {
            parsedSlots.add(DeviceSlotSchedule.fromList(item));
          } catch (_) {}
        } else if (item is Map) {
          try {
            parsedSlots.add(DeviceSlotSchedule.fromJson(item));
          } catch (_) {}
        }
      }
    }

    if (rawData.isNotEmpty) {
      final fromStr = DeviceOtherData.fromString(rawData);
      for (final s in fromStr.slots) {
        if (!parsedSlots.any((existing) => existing.index == s.index)) {
          parsedSlots.add(s);
        }
      }
      parsedSlots.sort((a, b) => a.index.compareTo(b.index));
    }

    dynamic progRaw = json['progTime'] ??
                      json['prog_time'] ??
                      json['programmedAt'] ?? 
                      json['programmed_at'] ?? 
                      json['progAt'] ?? 
                      json['prog_at'] ?? 
                      json['programTime'] ?? 
                      json['program_time'] ?? 
                      json['programmedTime'] ?? 
                      json['programmed_time'] ?? 
                      json['progDate'] ?? 
                      json['prog_date'] ?? 
                      json['programmed'] ?? 
                      json['timestamp'] ?? 
                      json['ts'] ?? 
                      json['pt'] ?? 
                      json['mfgDate'] ?? 
                      json['mfg_date'];

    if (progRaw == null) {
      for (final entry in json.entries) {
        final keyLower = entry.key.toLowerCase().replaceAll('_', '').replaceAll('-', '');
        if (keyLower.contains('progtime') ||
            keyLower.contains('program') ||
            keyLower.contains('progat') ||
            keyLower.contains('mfg') ||
            keyLower == 'pt' ||
            keyLower == 'ts' ||
            keyLower == 'timestamp') {
          progRaw = entry.value;
          break;
        }
      }
    }

    int? parsedProg;
    if (progRaw is num) {
      parsedProg = progRaw.toInt();
    } else if (progRaw is String && progRaw.trim().isNotEmpty) {
      final trimmed = progRaw.trim();
      parsedProg = int.tryParse(trimmed);
      if (parsedProg == null) {
        final d = double.tryParse(trimmed);
        if (d != null) {
          parsedProg = d.toInt();
        }
      }
      if (parsedProg == null) {
        final dt = DateTime.tryParse(trimmed);
        if (dt != null) {
          parsedProg = dt.millisecondsSinceEpoch ~/ 1000;
        } else {
          final formats = [
            'dd-MM-yyyy HH:mm:ss',
            'dd/MM/yyyy HH:mm:ss',
            'yyyy-MM-dd HH:mm:ss',
            'yyyy/MM/dd HH:mm:ss',
            'dd-MM-yyyy hh:mm a',
            'dd/MM/yyyy hh:mm a',
            'dd MMM yyyy, hh:mm a',
            'dd MMM yyyy hh:mm a',
            'dd MMM yyyy',
            'dd-MM-yyyy',
            'dd/MM/yyyy',
            'yyyy-MM-dd',
            'MM/dd/yyyy',
          ];
          for (final fmt in formats) {
            try {
              final parsedDt = DateFormat(fmt).parse(trimmed);
              parsedProg = parsedDt.millisecondsSinceEpoch ~/ 1000;
              break;
            } catch (_) {}
          }
        }
      }
    } else if (progRaw is DateTime) {
      parsedProg = progRaw.millisecondsSinceEpoch ~/ 1000;
    }

    final dynamic hwRaw = json['hwV'] ?? json['hw_v'] ?? json['hwVersion'] ?? json['hw_version'] ?? json['hw'] ?? json['hardware_version'] ?? json['hardware'];
    int? parsedHw;
    if (hwRaw is num) {
      parsedHw = hwRaw.toInt();
    } else if (hwRaw is String && hwRaw.trim().isNotEmpty) {
      final hwStr = hwRaw.trim();
      parsedHw = int.tryParse(hwStr);
      if (parsedHw == null) {
        final numMatch = RegExp(r'(\d+)').firstMatch(hwStr);
        if (numMatch != null) {
          parsedHw = int.tryParse(numMatch.group(1)!);
        }
      }
    }

    final dynamic verRaw = json['fwV'] ?? json['fw_v'] ?? json['version'] ?? json['fwVersion'] ?? json['fw_version'] ?? json['fw'] ?? json['v'] ?? json['firmware_version'];

    return DeviceOtherData(
      version: verRaw?.toString(),
      hwVersion: parsedHw,
      programmedAt: parsedProg,
      slots: parsedSlots,
      rawData: rawData,
    );
  }

  factory DeviceOtherData.fromString(String raw) {
    if (raw.trim().isEmpty) return const DeviceOtherData();
    try {
      final firstBrace = raw.indexOf('{');
      final lastBrace = raw.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        final candidate = raw.substring(firstBrace, lastBrace + 1);
        try {
          final decoded = jsonDecode(candidate);
          if (decoded is Map<String, dynamic>) {
            return DeviceOtherData.fromJson(decoded, rawData: candidate);
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Regex fallback for partial chunks
    String? version;
    final verMatch = RegExp(r'"(?:fwV|fw_v|version|fwVersion|fw_version|v)"\s*:\s*"([^"]+)"', caseSensitive: false).firstMatch(raw);
    if (verMatch != null) version = verMatch.group(1);

    int? hwVersion;
    final hwMatch = RegExp(r'"(?:hwV|hw_v|hwVersion|hw_version|hw)"\s*:\s*(\d+)', caseSensitive: false).firstMatch(raw);
    if (hwMatch != null) hwVersion = int.tryParse(hwMatch.group(1)!);

    int? programmedAt;
    final progMatch = RegExp(r'"(?:programmedAt|programmed_at|progTime|prog_time|programTime|progAt|timestamp|ts)"\s*:\s*(\d+)', caseSensitive: false).firstMatch(raw);
    if (progMatch != null) programmedAt = int.tryParse(progMatch.group(1)!);

    // Regex extraction for slots from string
    final List<DeviceSlotSchedule> extractedSlots = [];
    final Set<int> seenIndices = {};

    // 1. Array format slots: [index, start, end] e.g. [0,1787967000,1787970600]
    final arraySlotMatches = RegExp(r'\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\]').allMatches(raw);
    for (final m in arraySlotMatches) {
      final idx = int.tryParse(m.group(1)!);
      final start = int.tryParse(m.group(2)!);
      final end = int.tryParse(m.group(3)!);
      if (idx != null && !seenIndices.contains(idx)) {
        extractedSlots.add(DeviceSlotSchedule(
          index: idx,
          name: DeviceSlotSchedule.defaultSlotName(idx),
          start: start ?? 0,
          end: end ?? 0,
        ));
        seenIndices.add(idx);
      }
    }

    // 2. Complete Map format slots: {"i":0,...}
    final slotMatches = RegExp(r'\{[^{}]*"(?:i|index)"\s*:\s*\d+[^}]*\}').allMatches(raw);
    for (final m in slotMatches) {
      try {
        final str = m.group(0)!;
        final dec = jsonDecode(str);
        if (dec is Map) {
          final slot = DeviceSlotSchedule.fromJson(dec);
          if (!seenIndices.contains(slot.index)) {
            extractedSlots.add(slot);
            seenIndices.add(slot.index);
          }
        }
      } catch (_) {}
    }

    // 3. Trailing partial slot object (when closing '}' or ']' is truncated by BLE MTU buffer)
    final lastOpenBrace = raw.lastIndexOf('{');
    final lastCloseBrace = raw.lastIndexOf('}');
    if (lastOpenBrace != -1 && lastOpenBrace > lastCloseBrace) {
      final trailing = raw.substring(lastOpenBrace);
      final idxMatch = RegExp(r'"(?:i|index)"\s*:\s*(\d+)', caseSensitive: false).firstMatch(trailing);
      if (idxMatch != null) {
        final idx = int.tryParse(idxMatch.group(1)!);
        if (idx != null && !seenIndices.contains(idx)) {
          final nameMatch = RegExp(r'"(?:name|n)"\s*:\s*"([^"]+)"?', caseSensitive: false).firstMatch(trailing);
          final startMatch = RegExp(r'"(?:start|s)"\s*:\s*(\d+)', caseSensitive: false).firstMatch(trailing);
          final endMatch = RegExp(r'"(?:end|e)"\s*:\s*(\d+)', caseSensitive: false).firstMatch(trailing);

          extractedSlots.add(DeviceSlotSchedule(
            index: idx,
            name: nameMatch?.group(1) ?? DeviceSlotSchedule.defaultSlotName(idx),
            start: startMatch != null ? (int.tryParse(startMatch.group(1)!) ?? 0) : 0,
            end: endMatch != null ? (int.tryParse(endMatch.group(1)!) ?? 0) : 0,
          ));
          seenIndices.add(idx);
        }
      }
    }

    extractedSlots.sort((a, b) => a.index.compareTo(b.index));

    return DeviceOtherData(
      version: version,
      hwVersion: hwVersion,
      programmedAt: programmedAt,
      slots: extractedSlots,
      rawData: raw,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'hwVersion': hwVersion,
        'programmedAt': programmedAt,
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  DateTime? get programmedAtDateTime {
    if (programmedAt == null || programmedAt! <= 0) return null;
    try {
      // 10-digit epoch timestamp is in seconds (e.g. 1787936586) -> * 1000 to get ms
      final int ms = programmedAt! < 10000000000 ? (programmedAt! * 1000) : programmedAt!;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  String get formattedProgrammedAt {
    final dt = programmedAtDateTime;
    if (dt == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }
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

  static String defaultSlotName(int index) {
    switch (index) {
      case 0:
        return 'Wakeup Time';
      case 1:
        return 'Breakfast Time';
      case 2:
        return 'Mid-Morning';
      case 3:
        return 'Lunch Time';
      case 4:
        return 'Mid-Afternoon';
      case 5:
        return 'Evening';
      case 6:
        return 'After Dinner';
      default:
        return 'Slot $index';
    }
  }

  factory DeviceSlotSchedule.fromList(List<dynamic> list) {
    int parseNum(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) {
        return int.tryParse(val.trim()) ?? (double.tryParse(val.trim())?.toInt() ?? 0);
      }
      return 0;
    }

    final int idx = list.isNotEmpty ? parseNum(list[0]) : 0;
    final int start = list.length > 1 ? parseNum(list[1]) : 0;
    final int end = list.length > 2 ? parseNum(list[2]) : 0;

    return DeviceSlotSchedule(
      index: idx,
      name: defaultSlotName(idx),
      start: start,
      end: end,
    );
  }

  factory DeviceSlotSchedule.fromJson(Map<dynamic, dynamic> json) {
    int parseNum(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) {
        return int.tryParse(val.trim()) ?? (double.tryParse(val.trim())?.toInt() ?? 0);
      }
      return 0;
    }

    final int idx = parseNum(json['i'] ?? json['index'] ?? json['idx'] ?? json['id']);
    final String? explicitName = (json['name'] ?? json['n'] ?? json['title'])?.toString();
    final String name = (explicitName != null && explicitName.trim().isNotEmpty)
        ? explicitName
        : defaultSlotName(idx);

    return DeviceSlotSchedule(
      index: idx,
      name: name,
      start: parseNum(json['start'] ?? json['s'] ?? json['startTime'] ?? json['start_time']),
      end: parseNum(json['end'] ?? json['e'] ?? json['endTime'] ?? json['end_time']),
    );
  }

  Map<String, dynamic> toJson() => {
        'i': index,
        'name': name,
        'start': start,
        'end': end,
      };

  DateTime? get startDateTime {
    if (start <= 0) return null;
    try {
      if (start > 100000000) {
        final int ms = start < 10000000000 ? (start * 1000) : start;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      } else {
        final now = DateTime.now();
        final hours = start ~/ 3600;
        final minutes = (start % 3600) ~/ 60;
        final seconds = start % 60;
        return DateTime(now.year, now.month, now.day, hours, minutes, seconds);
      }
    } catch (_) {
      return null;
    }
  }

  DateTime? get endDateTime {
    if (end > 0) {
      try {
        if (end > 100000000) {
          final int ms = end < 10000000000 ? (end * 1000) : end;
          return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
        } else {
          final now = DateTime.now();
          final hours = end ~/ 3600;
          final minutes = (end % 3600) ~/ 60;
          final seconds = end % 60;
          return DateTime(now.year, now.month, now.day, hours, minutes, seconds);
        }
      } catch (_) {
        return null;
      }
    }

    // Fallback if end timestamp was truncated by BLE MTU buffer
    final sDt = startDateTime;
    if (sDt != null) {
      return sDt.add(const Duration(hours: 1));
    }

    return null;
  }
}
