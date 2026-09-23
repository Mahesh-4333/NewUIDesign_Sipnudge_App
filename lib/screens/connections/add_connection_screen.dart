import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/helpers/nudge_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/connection_model.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:hydrify/services/firebase_messaging_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hydrify/widgets/animated_nudge_button.dart';

class AddConnectionScreen extends StatefulWidget {
  final VoidCallback? onConnectionChanged;

  const AddConnectionScreen({super.key, this.onConnectionChanged});

  @override
  State<AddConnectionScreen> createState() => _AddConnectionScreenState();
}

class _AddConnectionScreenState extends State<AddConnectionScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedTabIndex = 0; // 0: Find & Discover, 1: Request
  bool _isLoading = true;
  String? _currentUserId;

  List<SearchedUser> _searchResults = [];
  List<PendingInvitation> _pendingInvitations = [];
  List<ConnectionMember> _recentlyJoined = [];

  StreamSubscription<void>? _connectionUpdateSub;

  // Default fallback contacts for "Invite from Contacts" section
  final List<Map<String, String>> _contactsList = [
    {
      'initials': 'MV',
      'name': 'Marcus Vance',
      'subtitle': 'Not on Sipnudge yet · Stay accountable',
    },
    {
      'initials': 'AL',
      'name': 'Aisha Lee',
      'subtitle': 'Not on Sipnudge yet · Stay accountable',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initData();

    // Auto-refresh when connection_request or connection_accepted FCM arrives
    _connectionUpdateSub =
        FirebaseMessagingService.connectionUpdateStream.stream.listen((_) {
      if (mounted) _fetchData();
    });
  }

  @override
  void dispose() {
    _connectionUpdateSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    _currentUserId = await SharedPrefsHelper.getUserId();
    await _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      if (_currentUserId != null) {
        final connectionsData =
            await _apiService.getConnections(_currentUserId!);
        if (connectionsData != null) {
          final parsed = ConnectionsDataResponse.fromJson(connectionsData);
          if (mounted) {
            setState(() {
              _pendingInvitations = parsed.pendingInvitations;
              _recentlyJoined = parsed.recentlyJoined;
            });
          }
        }

        // Initial default search
        await _performSearch(_searchController.text);
      } else {
        _setMockData();
      }
    } catch (e) {
      debugPrint("Error fetching connection requests: $e");
      _setMockData();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setMockData() {
    setState(() {
      _searchResults = [
        SearchedUser(
          userId: 'user_1',
          name: 'Name_123',
          userName: 'name_123',
          relationStatus: 'none',
        ),
        SearchedUser(
          userId: 'user_2',
          name: 'Dev Kapoor',
          userName: 'devkapoor',
          relationStatus: 'requested',
        ),
      ];

      _pendingInvitations = [
        PendingInvitation(
          connectionId: 'conn_1',
          userId: 'user_riya',
          name: 'Riya Sharma',
          userName: 'riyasharma',
          relativeTime: '12m ago',
        ),
        PendingInvitation(
          connectionId: 'conn_2',
          userId: 'user_dev',
          name: 'Dev Kapoor',
          userName: 'devkapoor',
          relativeTime: '45m ago',
        ),
      ];

      _recentlyJoined = [
        ConnectionMember(
          connectionId: 'conn_mom',
          userId: 'user_mom',
          name: 'Mom',
          userName: 'mom',
          relationshipTag: 'Mom',
          themeAccentColor: '#F97316',
          status: 'Active',
          connectedSubtitle: 'Connected today · 8-day streak',
        ),
      ];
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final results = await _apiService.searchUsers(
        query: query,
        userId: _currentUserId,
      );

      if (mounted) {
        setState(() {
          if (results.isNotEmpty) {
            _searchResults =
                results.map((e) => SearchedUser.fromJson(e)).toList();
          } else if (query.isEmpty) {
            // Default sample items if search is empty
            _searchResults = [
              SearchedUser(
                userId: 'user_1',
                name: 'Name_123',
                userName: 'name_123',
                relationStatus: 'none',
              ),
              SearchedUser(
                userId: 'user_2',
                name: 'Dev Kapoor',
                userName: 'devkapoor',
                relationStatus: 'requested',
              ),
            ];
          } else {
            _searchResults = [];
          }
        });
      }
    } catch (e) {
      debugPrint("Error performing search: $e");
    }
  }

  Future<void> _sendInvite(SearchedUser user) async {
    if (_currentUserId == null) return;
    setState(() {
      user.relationStatus = 'requested';
    });

    try {
      await _apiService.sendConnectionInvite(
        requesterId: _currentUserId!,
        recipientId: user.userId,
      );
      widget.onConnectionChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invitation sent to ${user.name}!"),
            backgroundColor: const Color(0xFF007AFF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error sending invite: $e");
    }
  }

  Future<void> _respondToInvitation(
      PendingInvitation inv, String action) async {
    if (_currentUserId == null) return;

    setState(() {
      _pendingInvitations
          .removeWhere((i) => i.connectionId == inv.connectionId);
    });

    try {
      await _apiService.respondConnectionInvite(
        connectionId: inv.connectionId,
        action: action,
        userId: _currentUserId!,
      );
      widget.onConnectionChanged?.call();
      _fetchData();
    } catch (e) {
      debugPrint("Error responding to invitation: $e");
    }
  }

  void _shareAppInvite(String name) {
    Share.share(
      "Hey $name! I'm tracking my hydration on Sipnudge. Let's connect and keep each other accountable: https://sipnudge.com",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onTap: () => Navigator.pop(context),
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
                          "Add Connection",
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

              // Segmented Tabs [ Find & Discover | Request ]
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.dim20.w,
                  vertical: 6.h,
                ),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: AppStyle.boxShadowVariation3,
                  ),
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
                              boxShadow: _selectedTabIndex == 0
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0083FF)
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                "Find & Discover",
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
                              boxShadow: _selectedTabIndex == 1
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0083FF)
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                "Request",
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
                    : (_selectedTabIndex == 0
                        ? _buildFindAndDiscoverTab()
                        : _buildRequestTab()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: Find & Discover
  // ==========================================
  Widget _buildFindAndDiscoverTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.dim20.w,
        vertical: 16.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: const Color(0xFF93C5FD),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0083FF).withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0083FF),
                  size: 22,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _performSearch(val),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF003057),
                    ),
                    decoration: InputDecoration(
                      hintText: "Riya",
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 20.h),

          // PEOPLE ON SIPNUDGE Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PEOPLE ON SIPNUDGE",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: AppColors.greyColorText1,
                  fontVariations: [AppFontStyles.boldFontVariation],
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "See All",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF0083FF),
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // People Cards
          ..._searchResults.map((user) => _buildUserCard(user)),

          SizedBox(height: 20.h),

          // INVITE FROM CONTACTS Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "INVITE FROM CONTACTS",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                "SMS / WhatsApp",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Contact cards
          ..._contactsList.map((contact) => _buildContactCard(contact)),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildUserCard(SearchedUser user) {
    final initials = user.name.isNotEmpty
        ? (user.name.trim().split(' ').length > 1
            ? "${user.name.trim().split(' ')[0][0]}${user.name.trim().split(' ')[1][0]}"
            : user.name.substring(0, user.name.length >= 2 ? 2 : 1))
        : 'U';

    final bool isRequested = user.relationStatus == 'requested';
    final bool isConnected = user.relationStatus == 'connected';

    final Color ringColor =
        isRequested ? const Color(0xFF2563EB) : const Color(0xFFF97316);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55.w,
            height: 55.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ringColor.withValues(alpha: 0.05),
              border: Border.all(color: ringColor, width: 2),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontWeight: FontWeight.w700,
                  color: ringColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              user.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: const Color(0xFF003057),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isConnected)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                "Connected",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (isRequested)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check,
                    size: 12,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    "Requested",
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: AppColors.greyColorText1,
                        fontVariations: [AppFontStyles.boldFontVariation]),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => _sendInvite(user),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0083FF),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  "+ Invite",
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: Colors.white,
                      fontVariations: [AppFontStyles.boldFontVariation]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, String> contact) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xFFF1F5F9),
            child: Text(
              contact['initials']!,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name']!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF003057),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  contact['subtitle']!,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _shareAppInvite(contact['name']!),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFF93C5FD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.share_outlined,
                    color: Color(0xFF0083FF),
                    size: 14,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    "Invite",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF0083FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: Request
  // ==========================================
  Widget _buildRequestTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.dim20.w,
        vertical: 14.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PENDING INVITATIONS Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "PENDING INVITATIONS",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    width: 18.w,
                    height: 18.w,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0083FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${_pendingInvitations.length}",
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                "Auto-expires in 7d",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Pending Invitation Cards
          if (_pendingInvitations.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  "No pending invitations",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            ..._pendingInvitations
                .map((inv) => _buildPendingInvitationCard(inv)),

          SizedBox(height: 20.h),

          // RECENTLY JOINED Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "RECENTLY JOINED",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  "View League",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF0083FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Recently Joined cards
          ..._recentlyJoined.map((mem) => _buildRecentlyJoinedCard(mem)),

          SizedBox(height: 20.h),

          // Sync Power Info Card
          _buildSyncPowerInfoCard(),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildPendingInvitationCard(PendingInvitation inv) {
    final initials = inv.name.isNotEmpty
        ? (inv.name.trim().split(' ').length > 1
            ? "${inv.name.trim().split(' ')[0][0]}${inv.name.trim().split(' ')[1][0]}"
            : inv.name.substring(0, inv.name.length >= 2 ? 2 : 1))
        : 'U';

    final Color ringColor = inv.name.toLowerCase().contains('riya')
        ? const Color(0xFFF97316)
        : const Color(0xFF2563EB);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: ringColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontWeight: FontWeight.bold,
                      color: ringColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  inv.name,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF003057),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                inv.relativeTime,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _respondToInvitation(inv, 'decline'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Center(
                      child: Text(
                        "Decline",
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => _respondToInvitation(inv, 'accept'),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Accept",
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
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

  Widget _buildRecentlyJoinedCard(ConnectionMember member) {
    final displayName = member.relationshipTag.isNotEmpty ? member.relationshipTag : member.name;
    final initial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'M';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: member.accentColor, width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontWeight: FontWeight.bold,
                  color: member.accentColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.relationshipTag.isNotEmpty ? member.relationshipTag : member.name,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: const Color(0xFF003057),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        "Active",
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  member.connectedSubtitle ?? "Connected today · 8-day streak",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          AnimatedNudgeButton(
            onTap: () async {
              await NudgeHelper.triggerNudge(
                context: context,
                currentUserId: _currentUserId,
                targetUserId: member.userId,
                targetUserName: member.relationshipTag.isNotEmpty
                    ? member.relationshipTag
                    : member.name,
              );
            },
            horizontalPadding: 16.w,
            verticalPadding: 7.h,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncPowerInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFD0E2FB), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            AssetsPath.syncPower,
            width: 20.w,
            height: 20.w,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sync Power",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF003057),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "When a connection is accepted, your hydration milestones sync in real-time. Nudge each other to prevent afternoon hydration dips!",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
