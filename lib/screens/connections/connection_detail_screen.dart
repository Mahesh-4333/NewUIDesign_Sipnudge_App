import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/helpers/nudge_helper.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/models/connection_model.dart';
import 'package:hydrify/services/api_service.dart';

class ConnectionDetailScreen extends StatefulWidget {
  final ConnectionMember member;
  final VoidCallback? onUpdated;

  const ConnectionDetailScreen({
    super.key,
    required this.member,
    this.onUpdated,
  });

  @override
  State<ConnectionDetailScreen> createState() => _ConnectionDetailScreenState();
}

class _ConnectionDetailScreenState extends State<ConnectionDetailScreen> {
  final ApiService _apiService = ApiService();
  late ConnectionMember _member;
  String _selectedTag = 'Mom';
  String _selectedHexColor = '#F97316';
  bool _isNudging = false;

  final List<Map<String, String>> _colorPalette = [
    {'name': 'Vibrant Orange', 'hex': '#F97316'},
    {'name': 'Ocean Blue', 'hex': '#2563EB'},
    {'name': 'Emerald Green', 'hex': '#10B981'},
    {'name': 'Royal Purple', 'hex': '#8B5CF6'},
    {'name': 'Teal Cyan', 'hex': '#06B6D4'},
    {'name': 'Coral Red', 'hex': '#F43F5E'},
  ];

  final List<String> _relationshipTags = [
    'Mom',
    'Dad',
    'Brother',
    'Sister',
    'Friend',
    'Wife',
  ];

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _selectedTag = _member.relationshipTag;
    _selectedHexColor = _member.themeAccentColor;
  }

  Color _parseHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) return Color(int.parse('0xFF$clean'));
      if (clean.length == 8) return Color(int.parse('0x$clean'));
    } catch (_) {}
    return const Color(0xFFF97316);
  }

  String _getColorName(String hex) {
    final match = _colorPalette.firstWhere(
      (c) => c['hex']?.toUpperCase() == hex.toUpperCase(),
      orElse: () => {'name': 'Custom', 'hex': hex},
    );
    return match['name'] ?? 'Custom';
  }

  Future<void> _updateCustomization({String? newTag, String? newHex}) async {
    final updatedTag = newTag ?? _selectedTag;
    final updatedHex = newHex ?? _selectedHexColor;

    setState(() {
      _selectedTag = updatedTag;
      _selectedHexColor = updatedHex;
      _member.relationshipTag = updatedTag;
      _member.themeAccentColor = updatedHex;
    });

    try {
      final currentUserId = await SharedPrefsHelper.getUserId();
      if (currentUserId != null && _member.connectionId.isNotEmpty) {
        await _apiService.customizeConnection(
          connectionId: _member.connectionId,
          userId: currentUserId,
          relationshipTag: updatedTag,
          themeAccentColor: updatedHex,
        );
        widget.onUpdated?.call();
      }
    } catch (e) {
      debugPrint("Error saving customization: $e");
    }
  }

  Future<void> _sendNudge() async {
    if (_isNudging) return;
    setState(() => _isNudging = true);

    await NudgeHelper.triggerNudge(
      context: context,
      currentUserId: await SharedPrefsHelper.getUserId(),
      targetUserId: _member.userId,
      targetUserName: _member.name,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    if (mounted) setState(() => _isNudging = false);
  }

  Future<void> _confirmRemoveConnection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "Remove Connection?",
          style: TextStyle(
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003057),
          ),
        ),
        content: Text(
          "Are you sure you want to remove ${_member.name} from your Social League? This will stop shared hydration sync.",
          style: TextStyle(
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: 14.sp,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Remove",
              style: TextStyle(
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        if (_member.connectionId.isNotEmpty) {
          await _apiService.removeConnection(_member.connectionId);
        }
        widget.onUpdated?.call();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        debugPrint("Error removing connection: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _parseHex(_selectedHexColor);

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
                          _member.name,
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

              // Content Cards
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.dim20.w,
                    vertical: 8.h,
                  ),
                  child: Column(
                    children: [
                      // Card 1: Profile Header
                      _buildProfileHeaderCard(),
                      SizedBox(height: 16.h),

                      // Card 2: Hydration Progress
                      _buildHydrationCard(currentColor),
                      SizedBox(height: 16.h),

                      // Card 3: Customization & Profile
                      _buildCustomizationCard(currentColor),
                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    final initial = _member.name.isNotEmpty
        ? _member.name.substring(0, 1).toUpperCase()
        : 'U';

    final bool isOnTrack = _member.status.toLowerCase() == 'on track';
    final bool isAchieved = _member.status.toLowerCase() == 'achieved';

    Color badgeBg = const Color(0xFFDCFCE7);
    Color badgeText = const Color(0xFF16A34A);
    if (!isOnTrack && !isAchieved) {
      badgeBg = const Color(0xFFE0F2FE);
      badgeText = const Color(0xFF0284C7);
    } else if (isOnTrack) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF16A34A);
    }

    return Container(
      width: double.infinity,
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
      padding: EdgeInsets.all(18.w),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar circle with border
              Container(
                width: 54.w,
                height: 54.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_member.name} (${_member.userName.isNotEmpty ? _member.userName : 'user'})",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: const Color(0xFF003057),
                        fontVariations: [AppFontStyles.boldFontVariation],
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        _member.status,
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
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Last sip: ${_member.lastSipRelative}",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: _sendNudge,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22.w,
                    vertical: 8.h,
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
                    _isNudging ? "Sending..." : "Nudge",
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

  Widget _buildHydrationCard(Color currentColor) {
    final double progress = (_member.target > 0)
        ? (_member.consumed / _member.target).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
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
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hydration",
            style: TextStyle(
              fontSize: 17.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: const Color(0xFF003057),
              fontVariations: [AppFontStyles.boldFontVariation],
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _member.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: const Color(0xFF003057),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${_member.percentage}%",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: currentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                RichText(
                  text: TextSpan(
                    text: "${_member.consumed.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF003057),
                    ),
                    children: [
                      TextSpan(
                        text: "/ ${_member.target.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ml",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(currentColor),
                    minHeight: 10.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationCard(Color currentColor) {
    return Container(
      width: double.infinity,
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
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Live Sync badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Customization & Profile",
                style: TextStyle(
                  fontSize: 17.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF003057),
                  fontVariations: [AppFontStyles.boldFontVariation],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Text(
                  "Live Sync",
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // Theme Accent Color row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Theme Accent Color",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getColorName(_selectedHexColor),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF003057),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Palette dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _colorPalette.map((col) {
              final hex = col['hex']!;
              final color = _parseHex(hex);
              final isSelected =
                  _selectedHexColor.toUpperCase() == hex.toUpperCase();

              return GestureDetector(
                onTap: () => _updateCustomization(newHex: hex),
                child: Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 22.h),

          // Relationship Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Relationship Tag",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Affects duo notifications",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Tag chips
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _relationshipTags.map((tag) {
              final isSelected = _selectedTag == tag;
              return GestureDetector(
                onTap: () => _updateCustomization(newTag: tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0083FF) : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0083FF)
                          : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0083FF).withOpacity(0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 24.h),

          // Remove Connection Button
          GestureDetector(
            onTap: _confirmRemoveConnection,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: const Color(0xFFFECDD3),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE11D48),
                    size: 18,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "Remove Connection",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFFE11D48),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: Text(
              "Removes ${_member.name} from your Social League and stops shared hydration sync.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
