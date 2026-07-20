import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/screens/sip_map_screen.dart';
import 'package:hydrify/screens/widgets/leaderboard_achievement_badge.dart';
import 'package:hydrify/services/api_service.dart';
import 'package:provider/provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _leaderboardData;

  @override
  void initState() {
    super.initState();
    _loadData();
    context.read<BottomNavCubit>().hideBar();
  }

  Future<void> _loadData() async {
    try {
      final uid = await SharedPrefsHelper.getUserId();
      if (uid != null) {
        final data = await _apiService.getLeaderboard(uid);
        if (mounted) {
          setState(() {
            _leaderboardData = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading leaderboard: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        Navigator.pop(context);
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
                      vertical: AppDimensions.dim10.h),
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
                            color: AppColors.white.withOpacity(0.2),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: AppColors.bluegray, size: 20),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Leaderboard",
                            style: TextStyle(
                              fontSize: AppFontStyles.fontSize_20.sp,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              color: AppColors.bluegray,
                              fontVariations: [AppFontStyles.boldFontVariation],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 40.w), // Balance back button
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppDimensions.dim24.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10.h),
                                  _buildGlobalImpactHeader(),
                                  SizedBox(height: AppDimensions.dim16.h),
                                  _buildGlobalRankingCard(),
                                  SizedBox(height: AppDimensions.dim24.h),
                                  _buildSocialImpactSection(),
                                  SizedBox(height: AppDimensions.dim24.h),
                                  _buildImpactStorySection(),
                                  SizedBox(height: AppDimensions.dim24.h),
                                  _buildSocialLeagueSection(),
                                  SizedBox(height: 40.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalImpactHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            "Global Impact",
            style: TextStyle(
              fontSize: 30.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: const Color(0xFF003057),
              fontVariations: [AppFontStyles.extraBoldFontVariation],
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Center(
          child: Text(
            "Track your contribution and social standing.",
            style: TextStyle(
              fontSize: 16.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: AppColors.bluegray,
              fontVariations: [AppFontStyles.semiBoldFontVariation],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalRankingCard() {
    final ranking = _leaderboardData?['globalRanking'] ??
        {
          'rank': 2,
          'totalUsers': 100,
          'percentile': 'Top 3%',
          'level': 10,
          'points': 850,
          'nextTierPoints': 1000,
          'tierName': 'Elite Tier'
        };

    final double progress = (ranking['points'] as num).toDouble() /
        (ranking['nextTierPoints'] as num).toDouble();

    // Percentile comes pre-computed from backend
    final String percentileDisplay = ranking['percentile'] as String? ?? 'Top 1%';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4D758B),
            Color(0xFFC2D2D9),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        children: [
          Row(
            children: [
              // Badge
              Transform.scale(
                scale: 1.4,
                child: LeaderboardAchievementBadge(
                  level: "${ranking['level']}",
                  width: 100.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Global \nRanking",
                      style: TextStyle(
                          fontSize: 20.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [
                            AppFontStyles.extraBoldFontVariation
                          ]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Top \n${percentileDisplay.replaceAll('Top ', '')}",
                    style: TextStyle(
                        fontSize: 30.sp,
                        color: Colors.white,
                        height: 1.3,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.extraBoldFontVariation]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),
          // Progress Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Progress to ${ranking['tierName']}",
                      style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontVariations: [
                            AppFontStyles.semiBoldFontVariation
                          ]),
                    ),
                    Text(
                      "${ranking['points']} / ${ranking['nextTierPoints']} pts",
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: const Color(0xFF00A2FF),
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.extraBoldFontVariation],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100.r),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF00A2FF)),
                    minHeight: 12.h,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSocialImpactSection() {
    final socialImpact =
        _leaderboardData?['socialImpact'] ?? {'activeFriendsCount': 3};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Social Impact",
              style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF003057),
                  fontVariations: [AppFontStyles.extraBoldFontVariation]),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SipMapScreen()),
                );
              },
              child: Row(
                children: [
                  Text(
                    "VIEW ALL",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: const Color(0xFF007BFF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  const Icon(Icons.arrow_forward,
                      size: 14, color: Color(0xFF007BFF)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SipMapScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            height: 160.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              color: Colors.blue.withOpacity(0.05),
            ),
            child: Stack(
              children: [
                // Stylized grid or dots to simulate map roads
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "${socialImpact['activeFriendsCount']} Friends Active Now",
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFFFF5252), size: 36),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          "San Francisco",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003057),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactStorySection() {
    final story = _leaderboardData?['impactStory'] ??
        {'bottlesSaved': 0, 'carbonReduced': 0.0};

    // bottlesSaved and carbonReduced come pre-computed from backend
    final int bottlesSaved = (story['bottlesSaved'] as num? ?? 0).toInt();
    final String carbonDisplay =
        (story['carbonReduced'] as num? ?? 0.0).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(AssetsPath.leaderWorld, width: 24.w, height: 24.h),
              SizedBox(width: 10.w),
              Text(
                "Your Impact Story",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF004976),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            "By maintaining this streak and opting for reusable hydration, you've significantly reduced your environmental footprint. Your daily commitment echoes beyond personal health.",
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 15.sp,
              fontVariations: [AppFontStyles.semiBoldFontVariation],
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: AppColors.darkgray,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                        color: const Color.fromARGB(255, 235, 235, 235),
                        width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        AssetsPath.leaderWaterIntake,
                        width: 44.w,
                        height: 44.h,
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.only(left: 2.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$bottlesSaved",
                              style: TextStyle(
                                fontSize: 27.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: const Color(0xFF003057),
                                fontVariations: [
                                  AppFontStyles.extraBoldFontVariation
                                ],
                              ),
                            ),
                            Text(
                              "BOTTLES SAVED",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                        color: const Color.fromARGB(255, 235, 235, 235),
                        width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        AssetsPath.leaderCo2,
                        width: 44.w,
                        height: 44.h,
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.only(left: 2.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$carbonDisplay kg",
                              style: TextStyle(
                                  fontSize: 27.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  color: const Color(0xFF1B5E20),
                                  fontVariations: [
                                    AppFontStyles.extraBoldFontVariation
                                  ]),
                            ),
                            Text(
                              "CARBON REDUCED",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontFamily: AppFontStyles.urbanistFontFamily,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLeagueSection() {
    final league = _leaderboardData?['socialLeague'] as List? ??
        [
          {
            'rank': 1,
            'name': 'Sarah J.',
            'level': 42,
            'points': 1240,
            'isMe': false,
            'avatar': 'assets/images/sarah.png'
          },
          {
            'rank': 2,
            'name': 'You',
            'level': 38,
            'points': 850,
            'isMe': true,
            'avatar': 'assets/images/user.png'
          },
          {
            'rank': 3,
            'name': 'Mike T.',
            'level': 35,
            'points': 720,
            'isMe': false,
            'avatar': 'assets/images/mike.png'
          }
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Social League",
              style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF003057),
                  fontVariations: [AppFontStyles.extraBoldFontVariation]),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Social League search coming soon!")),
                );
              },
              child: Text(
                "View All",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  color: const Color(0xFF007BFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Column(
            children: league.map((player) => _buildPlayerRow(player)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> player) {
    final bool isMe = player['isMe'] == true;

    return Container(
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEDF6FD) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
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
                decoration: BoxDecoration(
                  color: const Color(0xFF007BFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18.r),
                    bottomLeft: Radius.circular(18.r),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                // Rank number
                SizedBox(
                  width: 24.w,
                  child: Text(
                    "${player['rank']}",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: isMe
                          ? const Color(0xFF007BFF)
                          : const Color(0xFF003057),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8.w),
                // Avatar
                CircleAvatar(
                  radius: 20.r,
                  backgroundColor:
                      isMe ? const Color(0xFFBBDEFB) : Colors.grey.shade200,
                  child: isMe
                      ? const Icon(Icons.person, color: Color(0xFF007BFF))
                      : Text(
                          player['name'].substring(0, 1),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                ),
                SizedBox(width: 12.w),
                // Name and title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['name'],
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: isMe
                              ? const Color(0xFF007BFF)
                              : const Color(0xFF003057),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Level ${player['level']} Hydrator",
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Points
                Text(
                  "${player['points']} pts",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    color: const Color(0xFF003057),
                    fontWeight: FontWeight.bold,
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw stylized roads/grid lines
    canvas.drawLine(Offset(0, size.height * 0.3),
        Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(0, size.height * 0.7),
        Offset(size.width, size.height * 0.6), paint);
    canvas.drawLine(Offset(size.width * 0.3, 0),
        Offset(size.width * 0.4, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0),
        Offset(size.width * 0.6, size.height), paint);

    // Draw park circles
    final parkPaint = Paint()
      ..color = Colors.green.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.2), 30.r, parkPaint);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.75), 45.r, parkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
