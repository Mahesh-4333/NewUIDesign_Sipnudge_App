import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/helpers/nudge_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/connection_model.dart';
import 'package:hydrify/screens/connections/add_connection_screen.dart';
import 'package:hydrify/screens/connections/connection_detail_screen.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/firebase_messaging_service.dart';

class SocialLeagueScreen extends StatefulWidget {
  final int initialTabIndex; // 0 for Global, 1 for Connections
  const SocialLeagueScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SocialLeagueScreen> createState() => _SocialLeagueScreenState();
}

class _SocialLeagueScreenState extends State<SocialLeagueScreen> {
  final ApiService _apiService = ApiService();
  late int _selectedTabIndex;
  bool _isLoading = true;
  String? _currentUserId;

  // Global Tab Data
  List<Map<String, dynamic>> _globalLeague = [];

  // Connections Tab Data
  List<ConnectionMember> _connections = [];

  StreamSubscription<void>? _connectionUpdateSub;

  @override
  void initState() {
    super.initState();
    context.read<BottomNavCubit>().hideBar();
    _selectedTabIndex = widget.initialTabIndex;
    _loadData();

    // Auto-refresh when connection_request or connection_accepted FCM arrives
    _connectionUpdateSub =
        FirebaseMessagingService.connectionUpdateStream.stream.listen((_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _connectionUpdateSub?.cancel();
    context.read<BottomNavCubit>().showBar();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUserId = await SharedPrefsHelper.getUserId();

      if (_currentUserId != null) {
        // 1. Fetch Global leaderboard data
        final leaderboard = await _apiService.getLeaderboard(_currentUserId!);
        if (leaderboard != null) {
          final list = (leaderboard['socialLeague'] as List?) ?? [];
          _globalLeague =
              list.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        // 2. Fetch Connections data from API
        final connectionsData =
            await _apiService.getConnections(_currentUserId!);
        if (connectionsData != null) {
          final parsed = ConnectionsDataResponse.fromJson(connectionsData);
          _connections = parsed.connectedMembers;
        } else {
          _connections = [];
        }
      } else {
        _connections = [];
      }

      if (_globalLeague.isEmpty) {
        _setMockGlobalLeague();
      }
    } catch (e) {
      debugPrint("Error loading social league: $e");
      _connections = [];
      if (_globalLeague.isEmpty) {
        _setMockGlobalLeague();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setMockGlobalLeague() {
    _globalLeague = [
      {
        'rank': 1,
        'name': 'Sarah J.',
        'level': 42,
        'points': 1240,
        'isMe': false,
      },
      {
        'rank': 2,
        'name': 'You',
        'level': 38,
        'points': 850,
        'isMe': true,
      },
      {
        'rank': 3,
        'name': 'Mike T.',
        'level': 35,
        'points': 720,
        'isMe': false,
      },
      {
        'rank': 4,
        'name': 'Mike T.',
        'level': 35,
        'points': 720,
        'isMe': false,
      },
      {
        'rank': 5,
        'name': 'Mike T.',
        'level': 35,
        'points': 720,
        'isMe': false,
      },
      {
        'rank': 6,
        'name': 'Mike T.',
        'level': 35,
        'points': 720,
        'isMe': false,
      },
      {
        'rank': 7,
        'name': 'Mike T.',
        'level': 35,
        'points': 720,
        'isMe': false,
      },
    ];
  }

  Future<void> _sendNudge(ConnectionMember member) async {
    await NudgeHelper.triggerNudge(
      context: context,
      currentUserId: _currentUserId,
      targetUserId: member.userId,
      targetUserName: member.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<BottomNavCubit>().showBar();
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/app_background.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.dim20.w,
                    vertical: AppDimensions.dim12.h,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.read<BottomNavCubit>().showBar();
                          Navigator.pop(context);
                        },
                      child: Container(
                        padding: EdgeInsets.all(AppDimensions.dim8.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withOpacity(0.4),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF003057),
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Social League",
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: const Color(0xFF003057),
                            fontVariations: [
                              AppFontStyles.extraBoldFontVariation
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 36.w), // Balance back button
                  ],
                ),
              ),

              // Segmented Toggle Tab Bar [ Global | Connections ]
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.dim20.w,
                  vertical: 6.h,
                ),
                child: Container(
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0
                                  ? const Color(0xFF0083FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26.r),
                            ),
                            child: Center(
                              child: Text(
                                "Global",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  color: _selectedTabIndex == 0
                                      ? Colors.white
                                      : const Color(0xFF4D758B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1
                                  ? const Color(0xFF0083FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(26.r),
                            ),
                            child: Center(
                              child: Text(
                                "Connections",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  color: _selectedTabIndex == 1
                                      ? Colors.white
                                      : const Color(0xFF4D758B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab View Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: _selectedTabIndex == 0
                            ? _buildGlobalTab()
                            : _buildConnectionsTab(),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  // ==========================================
  // TAB 1: Global Rankings (Screenshot 2)
  // ==========================================
  Widget _buildGlobalTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.dim20.w,
        vertical: 14.h,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _globalLeague.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: Colors.grey.shade100,
          ),
          itemBuilder: (context, index) {
            final player = _globalLeague[index];
            return _buildGlobalPlayerRow(player);
          },
        ),
      ),
    );
  }

  Widget _buildGlobalPlayerRow(Map<String, dynamic> player) {
    final bool isMe = player['isMe'] == true;
    final int rank = (player['rank'] as num?)?.toInt() ?? 1;
    final String name = player['name'] ?? 'User';
    final int level = (player['level'] as num?)?.toInt() ?? 1;
    final int points = (player['points'] as num?)?.toInt() ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEDF6FD) : Colors.transparent,
      ),
      child: Stack(
        children: [
          if (isMe)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4.w,
                decoration: const BoxDecoration(
                  color: Color(0xFF0083FF),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 26.w,
                  child: Text(
                    "$rank",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF003057),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8.w),

                // Avatar / Bottle indicator
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMe
                        ? const Color(0xFFE0F2FE)
                        : const Color(0xFFF1F5F9),
                    border: isMe
                        ? Border.all(color: const Color(0xFF0083FF), width: 2)
                        : null,
                  ),
                  child: Center(
                    child: isMe
                        ? const Icon(
                            Icons.person,
                            color: Color(0xFF0083FF),
                            size: 24,
                          )
                        : Text(
                            name.isNotEmpty ? name.substring(0, 1) : 'U',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF475569),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 14.w),

                // Name and Hydrator Level
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: isMe
                              ? const Color(0xFF0083FF)
                              : const Color(0xFF003057),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Level $level Hydrator",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Points
                RichText(
                  text: TextSpan(
                    text: "${points.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF003057),
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: "pts",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: Connections (Screenshot 3)
  // ==========================================
  Widget _buildConnectionsTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.dim20.w,
              vertical: 14.h,
            ),
            child: Column(
              children: [
                if (_connections.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(30.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 48.sp,
                          color: const Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          "No connections yet",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: const Color(0xFF003057),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          "Connect with friends and family to keep each other hydrated!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._connections.map((member) => _buildConnectionCard(member)),
              ],
            ),
          ),
        ),

        // Bottom Add Connection Button
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.dim20.w,
            vertical: 14.h,
          ),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddConnectionScreen(
                    onConnectionChanged: _loadData,
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 52.h,
              decoration: BoxDecoration(
                color: const Color(0xFF0083FF),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0083FF).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "Add Connection",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(ConnectionMember member) {
    final double progress = (member.target > 0)
        ? (member.consumed / member.target).clamp(0.0, 1.0)
        : 0.0;

    final bool isOffTrack = member.status.toLowerCase() == 'off track';
    final bool isAchieved = member.status.toLowerCase() == 'achieved';

    Color badgeBg = const Color(0xFFE0F2FE);
    Color badgeText = const Color(0xFF0284C7);
    if (isOffTrack) {
      badgeBg = const Color(0xFFBAE6FD);
      badgeText = const Color(0xFF0369A1);
    } else if (isAchieved) {
      badgeBg = const Color(0xFFBAE6FD);
      badgeText = const Color(0xFF0284C7);
    }

    final accentColor = member.accentColor;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name + Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                member.name,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF003057),
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  member.status,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: badgeText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),

          // Last Sip info
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFF8B5E3C),
              ),
              SizedBox(width: 4.w),
              Text(
                "Last Sip: ${member.lastSip}",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF8B5E3C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Intake vs Goal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: "${member.consumed.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ",
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF003057),
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: "/ ${member.target.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ml",
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "${member.percentage}%",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE0F2FE),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 16.h),

          // Bottom Action Row: View Details link & Nudge button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConnectionDetailScreen(
                        member: member,
                        onUpdated: _loadData,
                      ),
                    ),
                  );
                },
                child: Text(
                  "View Details",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF007AFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _sendNudge(member),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0083FF),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0083FF).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    "Nudge",
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
