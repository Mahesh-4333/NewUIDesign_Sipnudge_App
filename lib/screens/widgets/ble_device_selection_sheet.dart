import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/cubit/ble/ble_cubit.dart';

class BleDeviceSelectionSheet extends StatelessWidget {
  const BleDeviceSelectionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<BleCubit, BleState>(
        buildWhen: (prev, curr) => prev.scannedDevices != curr.scannedDevices,
        builder: (context, state) {
          final filtered = state.scannedDevices
              .where((r) => r.device.name.isNotEmpty)
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(AppDimensions.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'No nearby bottles found.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppFontStyles.fontSize_14,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                            color: AppColors.white,
                            fontVariations: [
                              AppFontStyles.fontWeightVariation600
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.read<BleCubit>().start();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            minimumSize: Size(double.maxFinite, 50.h),
                          ),
                          child: Text(
                            'Retry Scan',
                            style: TextStyle(
                              fontSize: AppFontStyles.fontSize_20,
                              fontFamily: AppFontStyles.urbanistFontFamily,
                              color: AppColors.black,
                              fontVariations: [
                                AppFontStyles.fontWeightVariation600
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final r = filtered[index];
                        return DeviceListItem(
                          name: r.device.name,
                          onTap: () {
                            Navigator.of(context).pop();
                            context
                                .read<BleCubit>()
                                .connectToSelectedDevice(r.device);
                          },
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(
                        height: 10.h,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DeviceListItem extends StatefulWidget {
  final String name;
  final VoidCallback onTap;

  const DeviceListItem({
    super.key,
    required this.name,
    required this.onTap,
  });

  @override
  State<DeviceListItem> createState() => _DeviceListItemState();
}

class _DeviceListItemState extends State<DeviceListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100), // shorter = snappier
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic, // smoother start/end
      ),
    );
  }

  void _onTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: GlassmorphicContainer(
          width: double.infinity,
          borderRadius: 32.w,
          height: AppDimensions.dim65.h,
          blur: 50,
          alignment: Alignment.center,
          border: .8,
          linearGradient: LinearGradient(colors: [
            const Color(0XFF00D0FF).withOpacity(.15),
            const Color(0XFF00D0FF).withOpacity(.15),
          ]),
          borderGradient: LinearGradient(
            transform: GradientRotation(-.9),
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Colors.black,
              Colors.black,
              Colors.white,
              Colors.white,
              Colors.black,
              Colors.black,
            ],
          ),
          child: ListTile(
            dense: true,
            title: Text(
              widget.name,
              style: TextStyle(
                fontSize: AppFontStyles.fontSize_20.sp,
                fontFamily: AppFontStyles.urbanistFontFamily,
                fontVariations: [AppFontStyles.boldFontVariation],
                color: AppColors.white,
              ),
            ),
            trailing: const _FadingBleIcon(),
          ),
        ),
      ),
    );
  }
}

class _FadingBleIcon extends StatefulWidget {
  const _FadingBleIcon();

  @override
  State<_FadingBleIcon> createState() => _FadingBleIconState();
}

class _FadingBleIconState extends State<_FadingBleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true); // fade in & out
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SvgPicture.asset(
        "assets/images/ic_ble_signal.svg",
        width: 20.w,
        height: 20.h,
      ),
    );
  }
}
