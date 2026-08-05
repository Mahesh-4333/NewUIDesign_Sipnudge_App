import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_strings.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/services/api_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isMonthly = true;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _userAlreadyPremium = false;
  String _activeSubscriptionId = '';
  
  List<dynamic> _serverPlans = [];
  Map<String, dynamic>? _selectedPlan;

  // Fallbacks if backend doesn't return data
  final Map<String, dynamic> _fallbackMonthlyPlan = {
    '_id': 'mock_monthly_id',
    'name': 'Elite Upgrade Plan',
    'price': 4.99,
    'currency': 'USD',
    'description': 'Unlock the full potential of your hydration journey with precision metrics and advanced insights.',
    'features': [
      'Ad-free Experience: Focus entirely on your goals without any interruptions.',
      'Unlimited Tracking: Log every sip, supplement, and activity without limits.',
      'Advanced Hydration Insights: AI-driven patterns and predictive hydration schedules.',
      'Exclusive App Icons: Customize your home screen with premium digital aesthetics.'
    ]
  };

  final Map<String, dynamic> _fallbackYearlyPlan = {
    '_id': 'mock_yearly_id',
    'name': 'Elite Upgrade Plan',
    'price': 39.99,
    'currency': 'USD',
    'description': 'Unlock the full potential of your hydration journey with precision metrics and advanced insights.',
    'features': [
      'Ad-free Experience: Focus entirely on your goals without any interruptions.',
      'Unlimited Tracking: Log every sip, supplement, and activity without limits.',
      'Advanced Hydration Insights: AI-driven patterns and predictive hydration schedules.',
      'Exclusive App Icons: Customize your home screen with premium digital aesthetics.'
    ]
  };

  @override
  void initState() {
    super.initState();
    _checkUserStatusAndFetchPlans();
  }

  Future<void> _checkUserStatusAndFetchPlans() async {
    setState(() => _isLoading = true);
    try {
      final isPrem = await SharedPrefsHelper.isPremium();
      final userId = await SharedPrefsHelper.getUserId();
      
      if (isPrem && userId != null) {
        // Fetch user subscriptions to see details
        final subsRes = await ApiService().getUserSubscriptions(userId);
        if (subsRes != null && subsRes['data'] != null) {
          final List<dynamic> list = subsRes['data'];
          final activeSub = list.firstWhere(
            (s) => s['status'] == 'active' || s['status'] == 'trialing',
            orElse: () => null,
          );
          if (activeSub != null) {
            _activeSubscriptionId = activeSub['_id'] ?? '';
            _userAlreadyPremium = true;
          }
        }
      }

      final plans = await ApiService().getSubscriptionPlans();
      if (plans != null && plans.isNotEmpty) {
        setState(() {
          _serverPlans = plans;
          _selectedPlan = _resolveSelectedPlan();
        });
      } else {
        setState(() {
          _selectedPlan = _isMonthly ? _fallbackMonthlyPlan : _fallbackYearlyPlan;
        });
      }
    } catch (e) {
      debugPrint("Error loading subscription info: $e");
      setState(() {
        _selectedPlan = _isMonthly ? _fallbackMonthlyPlan : _fallbackYearlyPlan;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? _resolveSelectedPlan() {
    if (_serverPlans.isEmpty) {
      return _isMonthly ? _fallbackMonthlyPlan : _fallbackYearlyPlan;
    }
    
    // Find plan based on billingCycle field
    final matches = _serverPlans.where((p) {
      final billingCycle = (p['billingCycle'] as String? ?? '').toLowerCase();
      if (_isMonthly) {
        return billingCycle == 'monthly';
      } else {
        return billingCycle == 'yearly';
      }
    }).toList();

    // Fallback search to sku or name if billingCycle is not set on older products
    if (matches.isEmpty) {
      final fallbackMatches = _serverPlans.where((p) {
        final sku = (p['sku'] as String? ?? '').toLowerCase();
        final name = (p['name'] as String? ?? '').toLowerCase();
        if (_isMonthly) {
          return sku.contains('-mo') || sku.contains('monthly') || name.contains('monthly');
        } else {
          return sku.contains('-yr') || sku.contains('yearly') || name.contains('yearly');
        }
      }).toList();
      return fallbackMatches.isNotEmpty ? fallbackMatches.first : _serverPlans.first;
    }

    return matches.first;
  }

  void _onToggleCycle(bool isMonthly) {
    if (_isMonthly == isMonthly) return;
    setState(() {
      _isMonthly = isMonthly;
      _selectedPlan = _resolveSelectedPlan();
    });
  }

  String _formatPrice(num price, String currency) {
    if (currency.toUpperCase() == 'INR') {
      return '₹$price';
    }
    return '\$$price';
  }

  Future<void> _handleCancelSubscription() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.cancelSubscriptionTitle),
        content: const Text(AppStrings.cancelSubscriptionDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.keepMembership),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(AppStrings.confirmCancel),
          ),
        ],
      ),
    );

    if (confirm != true || _activeSubscriptionId.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService().cancelSubscription(_activeSubscriptionId);
      if (res != null) {
        await SharedPrefsHelper.setUserType('regular');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.subscriptionCancelledSuccessfully)),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.failedToCancelSubscription)),
          );
        }
      }
    } catch (e) {
      debugPrint("Error cancelling subscription: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleContinue() async {
    if (_selectedPlan == null) return;
    
    // Show Apple App Store simulated double-click to authorize modal sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAppStoreModal(),
    );
  }

  Future<void> _executeMockPurchase() async {
    Navigator.pop(context); // Close bottom sheet
    setState(() => _isSubmitting = true);

    try {
      final userId = await SharedPrefsHelper.getUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User account not found. Please log in again.')),
          );
        }
        return;
      }

      final planId = _selectedPlan?['_id'] ?? 'mock_plan_id';
      final billingCycle = _isMonthly ? 'monthly' : 'yearly';
      final price = (_selectedPlan?['price'] as num? ?? 4.99).toDouble();
      final gatewaySubscriptionId = 'sub_mock_${DateTime.now().millisecondsSinceEpoch}';

      final res = await ApiService().createSubscription(
        userId: userId,
        planId: planId,
        billingCycle: billingCycle,
        price: price,
        gatewaySubscriptionId: gatewaySubscriptionId,
      );

      if (res != null) {
        // Update user type locally
        await SharedPrefsHelper.setUserType('premium');
        
        if (mounted) {
          // Show beautiful success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64.w,
                      height: 64.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5F6FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF007BFF),
                        size: 36,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Elite Upgrade Active!',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF004976),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Welcome to Premium! You have unlocked ad-free experience, deep hydration insights, and customizable bottle configurations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(this.context, true); // Close subscription page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
                        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                      ),
                      child: Text(
                        'Start Exploring',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription failed. Please check your network.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Subscription error: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildAppStoreModal() {
    final priceStr = _formatPrice(_selectedPlan?['price'] ?? 4.99, _selectedPlan?['currency'] ?? 'USD');
    final cycleStr = _isMonthly ? '/month' : '/year';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.apple, size: 28),
                SizedBox(width: 8.w),
                Text(
                  'App Store',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(color: Colors.grey),
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007BFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPlan?['name'] ?? 'Elite Upgrade Plan',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sipnudge Hydration',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            _buildInfoRow('ACCOUNT', 'newton.singh@sipnudge.com'),
            _buildInfoRow('PRICE', '$priceStr$cycleStr'),
            _buildInfoRow('TERMS', 'Subscription will auto-renew. Cancel anytime in your App Store settings.'),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: _executeMockPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 16.h),
              ),
              child: Text(
                'Confirm - Double Click to Pay',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceStr = _formatPrice(_selectedPlan?['price'] ?? 4.99, _selectedPlan?['currency'] ?? 'USD');
    final cycleStr = _isMonthly ? '/month' : '/year';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Upgrade Plan',
          style: TextStyle(
            color: const Color(0xFF004976),
            fontSize: 20.sp,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset("assets/images/back_ic.svg"),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _userAlreadyPremium
              ? _buildAlreadyPremiumScreen()
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 16.h),
                      // Top Crown Circle
                      Container(
                        width: 72.w,
                        height: 72.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007BFF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007BFF).withOpacity(0.3),
                              blurRadius: 12.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: Size(32.w, 32.h),
                            painter: CrownPainter(),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Title & Subtitle
                      Text(
                        _selectedPlan?['name'] ?? 'Elite Upgrade Plan',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF004976),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Text(
                          _selectedPlan?['description'] ?? 'Unlock the full potential of your hydration journey with precision metrics and advanced insights.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(height: 32.h),
                      // Toggle Control (Monthly / Yearly)
                      Container(
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _onToggleCycle(true),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isMonthly ? const Color(0xFF007BFF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Monthly',
                                    style: TextStyle(
                                      color: _isMonthly ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppFontStyles.urbanistFontFamily,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _onToggleCycle(false),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !_isMonthly ? const Color(0xFF007BFF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(25.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Yearly',
                                    style: TextStyle(
                                      color: !_isMonthly ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontFamily: AppFontStyles.urbanistFontFamily,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      // Card containing features list
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  priceStr,
                                  style: TextStyle(
                                    fontSize: 48.sp,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF004976),
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  cycleStr,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            // Feature Items
                            ...(_selectedPlan?['features'] as List<dynamic>? ?? []).map((featureStr) {
                              final parts = (featureStr as String).split(':');
                              final title = parts[0];
                              final desc = parts.length > 1 ? parts[1].trim() : '';

                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20.w,
                                      height: 20.h,
                                      margin: EdgeInsets.only(top: 2.h),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE5F6FD),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Color(0xFF007BFF),
                                        size: 14,
                                      ),
                                    ),
                                    SizedBox(width: 16.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontFamily: AppFontStyles.urbanistFontFamily,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          if (desc.isNotEmpty) ...[
                                            SizedBox(height: 4.h),
                                            Text(
                                              desc,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                fontFamily: AppFontStyles.urbanistFontFamily,
                                                color: Colors.grey[600],
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      SizedBox(height: 32.h),
                      Text(
                        'Upgrade Now',
                        style: TextStyle(
                          color: const Color(0xFF004976),
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Checkout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
                          ),
                          child: _isSubmitting
                              ? const CupertinoActivityIndicator(color: Colors.white)
                              : Text(
                                  'Continue - $priceStr',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Cancel anytime in your App Store settings.',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12.sp,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                        ),
                      ),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAlreadyPremiumScreen() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 80.w,
            height: 80.h,
            decoration: const BoxDecoration(
              color: Color(0xFFE5F6FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Color(0xFF007BFF),
              size: 48,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'You are an Elite Member',
            style: TextStyle(
              fontSize: 22.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF004976),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Enjoy all premium features including advanced insights, ad-free tracking, and customizable options.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontFamily: AppFontStyles.urbanistFontFamily,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _handleCancelSubscription,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
              ),
              child: _isSubmitting
                  ? const CupertinoActivityIndicator(color: Colors.red)
                  : Text(
                      'Cancel Subscription',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}

class CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Draw the crown shape
    path.moveTo(size.width * 0.1, size.height * 0.85); // bottom left
    path.lineTo(size.width * 0.9, size.height * 0.85); // bottom right
    path.lineTo(size.width * 0.85, size.height * 0.40); // right peak edge
    path.lineTo(size.width * 0.68, size.height * 0.60); // right valley
    path.lineTo(size.width * 0.50, size.height * 0.25); // center peak
    path.lineTo(size.width * 0.32, size.height * 0.60); // left valley
    path.lineTo(size.width * 0.15, size.height * 0.40); // left peak edge
    path.close();

    canvas.drawPath(path, paint);

    // Draw bottom bar of the crown
    final rectPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.88, size.width * 0.8, size.height * 0.08),
        Radius.circular(2.r),
      ),
      rectPaint,
    );

    // Draw little circles on the 3 peaks
    final circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.36), size.width * 0.06, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.20), size.width * 0.07, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.36), size.width * 0.06, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
