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
  String lastSip;
  String lastSipRelative;
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
    this.lastSip = 'No sips yet',
    this.lastSipRelative = 'Recently',
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
      lastSip: json['lastSip']?.toString() ?? 'No sips yet',
      lastSipRelative: json['lastSipRelative']?.toString() ?? 'Recently',
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
      'lastSip': lastSip,
      'lastSipRelative': lastSipRelative,
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
