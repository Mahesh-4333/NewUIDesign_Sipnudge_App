import 'package:flutter/material.dart';

class ConnectionMember {
  final String connectionId;
  final String userId;
  String name;
  String userName;
  String relationshipTag;
  String themeAccentColor;
  String status;
  int consumed;
  int target;
  int percentage;
  int expectedPercent; // Yellow bar — schedule-based target progress
  String lastSip;
  String lastSipRelative;
  String? lastSipTimestamp;
  String? connectedSubtitle;

  ConnectionMember({
    required this.connectionId,
    required this.userId,
    required this.name,
    required this.userName,
    this.relationshipTag = 'Friend',
    this.themeAccentColor = '#F97316',
    this.status = 'On Track',
    this.consumed = 0,
    this.target = 2000,
    this.percentage = 0,
    this.expectedPercent = 0,
    this.lastSip = 'No sips yet',
    this.lastSipRelative = 'Recently',
    this.lastSipTimestamp,
    this.connectedSubtitle,
  });

  Color get accentColor {
    try {
      final hex = themeAccentColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('0xFF$hex'));
      } else if (hex.length == 8) {
        return Color(int.parse('0x$hex'));
      }
    } catch (_) {}
    return const Color(0xFFF97316); // Default Vibrant Orange
  }

  /// Yellow bar: expected progress based on user's slots (from API).
  /// Falls back to time-of-day estimate (7AM–10PM) if API doesn't provide it.
  double get expectedProgress {
    if (expectedPercent > 0) {
      return (expectedPercent / 100.0).clamp(0.0, 1.0);
    }
    // Fallback: time-based estimate over waking hours 7AM–10PM
    final now = DateTime.now();
    final hour = now.hour + now.minute / 60.0;
    const startHour = 7.0;
    const endHour = 22.0;
    if (hour <= startHour) return 0.0;
    if (hour >= endHour) return 1.0;
    return ((hour - startHour) / (endHour - startHour)).clamp(0.0, 1.0);
  }

  /// Returns formatted last sip string:
  /// - Today: "4:14 PM"
  /// - Past date: "Sep 20, 4:14 PM"
  /// - No data: "No sips yet"
  ///
  /// Server UTC timestamp (e.g., "2026-09-21T16:14:00.000Z") is converted
  /// to device local timezone using .toLocal()
  String get formattedLastSip {
    if (lastSipTimestamp == null || lastSipTimestamp!.isEmpty) {
      return lastSip;
    }

    try {
      // Parse UTC timestamp and convert to local timezone
      final timestamp = DateTime.parse(lastSipTimestamp!).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sipDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

      // Format time: 12-hour with AM/PM
      final hour24 = timestamp.hour;
      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour24 < 12 ? 'AM' : 'PM';
      final timeStr = '$hour12:$minute $period';

      if (sipDate == today) {
        // Today: show only time
        return timeStr;
      } else {
        // Past date: show date + time
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthStr = months[timestamp.month - 1];
        return '$monthStr ${timestamp.day}, $timeStr';
      }
    } catch (_) {
      return lastSip;
    }
  }

  factory ConnectionMember.fromJson(Map<String, dynamic> json) {
    return ConnectionMember(
      connectionId: json['connectionId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Connection',
      userName: json['userName']?.toString() ?? '',
      relationshipTag: json['relationshipTag']?.toString() ?? 'Friend',
      themeAccentColor: json['themeAccentColor']?.toString() ?? '#F97316',
      status: json['status']?.toString() ?? 'On Track',
      consumed: (json['consumed'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 2000,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
      expectedPercent: (json['expectedPercent'] as num?)?.toInt() ?? 0,
      lastSip: json['lastSip']?.toString() ?? 'No sips yet',
      lastSipRelative: json['lastSipRelative']?.toString() ?? 'Recently',
      lastSipTimestamp: json['lastSipTimestamp']?.toString(),
      connectedSubtitle: json['connectedSubtitle']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectionId': connectionId,
      'userId': userId,
      'name': name,
      'userName': userName,
      'relationshipTag': relationshipTag,
      'themeAccentColor': themeAccentColor,
      'status': status,
      'consumed': consumed,
      'target': target,
      'percentage': percentage,
      'expectedPercent': expectedPercent,
      'lastSip': lastSip,
      'lastSipRelative': lastSipRelative,
      'lastSipTimestamp': lastSipTimestamp,
      'connectedSubtitle': connectedSubtitle,
    };
  }
}

class PendingInvitation {
  final String connectionId;
  final String userId;
  final String name;
  final String userName;
  final String relativeTime;

  PendingInvitation({
    required this.connectionId,
    required this.userId,
    required this.name,
    required this.userName,
    required this.relativeTime,
  });

  factory PendingInvitation.fromJson(Map<String, dynamic> json) {
    return PendingInvitation(
      connectionId: json['connectionId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      userName: json['userName']?.toString() ?? '',
      relativeTime: json['relativeTime']?.toString() ?? 'Recently',
    );
  }
}

class SearchedUser {
  final String userId;
  final String name;
  final String userName;
  String relationStatus; // 'none', 'requested', 'pending_approval', 'connected'
  String? connectionId;

  SearchedUser({
    required this.userId,
    required this.name,
    required this.userName,
    this.relationStatus = 'none',
    this.connectionId,
  });

  factory SearchedUser.fromJson(Map<String, dynamic> json) {
    return SearchedUser(
      userId: json['userId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      userName: json['userName']?.toString() ?? '',
      relationStatus: json['relationStatus']?.toString() ?? 'none',
      connectionId: json['connectionId']?.toString(),
    );
  }
}

class ConnectionsDataResponse {
  final List<ConnectionMember> connectedMembers;
  final List<PendingInvitation> pendingInvitations;
  final List<SearchedUser> sentRequests;
  final List<ConnectionMember> recentlyJoined;

  ConnectionsDataResponse({
    required this.connectedMembers,
    required this.pendingInvitations,
    required this.sentRequests,
    required this.recentlyJoined,
  });

  factory ConnectionsDataResponse.fromJson(Map<String, dynamic> json) {
    final membersRaw = (json['connectedMembers'] as List?) ?? [];
    final pendingRaw = (json['pendingInvitations'] as List?) ?? [];
    final sentRaw = (json['sentRequests'] as List?) ?? [];
    final recentRaw = (json['recentlyJoined'] as List?) ?? [];

    return ConnectionsDataResponse(
      connectedMembers: membersRaw.map((e) => ConnectionMember.fromJson(e)).toList(),
      pendingInvitations: pendingRaw.map((e) => PendingInvitation.fromJson(e)).toList(),
      sentRequests: sentRaw.map((e) => SearchedUser.fromJson(e)).toList(),
      recentlyJoined: recentRaw.map((e) => ConnectionMember.fromJson(e)).toList(),
    );
  }
}
