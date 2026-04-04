import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrify/cubit/hydration/hydration_cubit.dart';
import 'package:hydrify/services/notification/notification_service.dart';
import 'package:intl/intl.dart';

class ActiveNotificationsScreen extends StatefulWidget {
  const ActiveNotificationsScreen({super.key});

  @override
  State<ActiveNotificationsScreen> createState() =>
      _ActiveNotificationsScreenState();
}

class _ActiveNotificationsScreenState extends State<ActiveNotificationsScreen> {
  List<ScheduledNotification> activeNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final hydrationCubit = context.read<HydrationCubit>();
    final entries = hydrationCubit.state.entries;
    
    // Fetch ONLY the effectively active scheduled notifications straight from the OS
    final notifications = await NotificationService()
        .getActiveScheduledNotifications(entries);

    setState(() {
      activeNotifications = notifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Active Notifications",
          style: TextStyle(
              color: AppColors.bluegray,
              fontSize: AppFontStyles.fontSize_AppBar,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontVariations: [
                AppFontStyles.boldFontVariation,
              ]),
        ),
        leadingWidth: AppDimensions.dim85.w,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: SvgPicture.asset(
            "assets/images/back_ic.svg",
          ),
        ),
      ),
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
          child: DefaultTextStyle(
            style: TextStyle(fontFamily: AppFontStyles.urbanistFontFamily),
            child: activeNotifications.isEmpty
                ? Center(
                    child: Text(
                      "No Active Notifications",
                      style: TextStyle(
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        color: AppColors.bluegray,
                        fontSize: AppFontStyles.fontSize_18.sp,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.dim20.w,
                      vertical: AppDimensions.dim20.h,
                    ),
                    itemCount: activeNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = activeNotifications[index];
                      final dateString = DateFormat('EEE, MMM dd - hh:mm a')
                          .format(notification.dateTime);

                      return Card(
                        elevation: 0,
                        color: AppColors.white1A,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xCCC6C6C6)),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radius_16.r),
                        ),
                        margin: EdgeInsets.only(bottom: AppDimensions.dim16.h),
                        child: Padding(
                          padding: EdgeInsets.all(AppDimensions.dim16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notification.title,
                                    style: TextStyle(
                                      color: AppColors.bluegray,
                                      fontSize: AppFontStyles.fontSize_18.sp,
                                      fontFamily: AppFontStyles.urbanistFontFamily,
                                      fontVariations: [
                                        AppFontStyles.boldFontVariation,
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "#${notification.id}",
                                    style: TextStyle(
                                      color: AppColors.bluegray.withValues(alpha: 0.5),
                                      fontSize: AppFontStyles.fontSize_12.sp,
                                      fontFamily: AppFontStyles.urbanistFontFamily,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppDimensions.dim4.h),
                              Text(
                                dateString,
                                style: TextStyle(
                                  color: AppColors.bluegray,
                                  fontSize: AppFontStyles.fontSize_16.sp,
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (notification.body.isNotEmpty) ...[
                                SizedBox(height: AppDimensions.dim4.h),
                                Text(
                                  notification.body,
                                  style: TextStyle(
                                    color: AppColors.bluegray.withValues(alpha: 0.7),
                                    fontSize: AppFontStyles.fontSize_14.sp,
                                    fontFamily: AppFontStyles.urbanistFontFamily,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
