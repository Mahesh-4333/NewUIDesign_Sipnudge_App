import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class AutoScrollGoalText extends StatefulWidget {
  final String text;

  const AutoScrollGoalText({super.key, required this.text});

  @override
  State<AutoScrollGoalText> createState() => _AutoScrollGoalTextState();
}

class _AutoScrollGoalTextState extends State<AutoScrollGoalText> {
  final ScrollController _controller = ScrollController();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScroll();
    });
  }

  Future<void> _startScroll() async {
    await Future.delayed(const Duration(seconds: 1));

    while (!_disposed && _controller.hasClients) {
      final max = _controller.position.maxScrollExtent;

      if (max > 0) {
        await _controller.animateTo(
          max,
          duration: const Duration(seconds: 30), // slow & readable
          curve: Curves.linear,
        );
      }

      if (_controller.hasClients) {
        _controller.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130.h, // visible area (like image)
      width: AppDimensions.dim350.w,
      child: SingleChildScrollView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildText(),
            SizedBox(height: 30.h),
            _buildText(), //duplicate for seamless scroll
          ],
        ),
      ),
    );
  }

  Widget _buildText() {
    return Text(
      widget.text,
      textAlign: TextAlign.center,
      softWrap: true,
      style: TextStyle(
        fontSize: AppFontStyles.fontSize_16,
        color: AppColors.bluegray,
        fontFamily: AppFontStyles.museoModernoFontFamily,
        fontVariations: [
          AppFontStyles.semiBoldFontVariation,
        ],
      ),
    );
  }
}
