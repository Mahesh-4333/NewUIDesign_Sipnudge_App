import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';

class CustomTextField extends StatefulWidget {
  final String? hint;
  final String? label;
  final Widget? prefixIcon;
  final bool isPasswordField;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final Color? borderColor;

  const CustomTextField({
    super.key,
    this.hint,
    this.label,
    this.prefixIcon,
    this.isPasswordField = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.borderColor,
  });

  @override
  State<CustomTextField> createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(curve);
  }

  void triggerShake() {
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radius_100.h),
          boxShadow: [
            BoxShadow(
              blurRadius: AppDimensions.radius_5,
              color: AppColors.black.withOpacity(.25),
              offset: Offset(AppDimensions.dim2, AppDimensions.dim2),
            )
          ],
        ),
        child: TextFormField(
          maxLines: 1,
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.isPasswordField ? _obscureText : false,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          obscuringCharacter: '●',
          style: TextStyle(
            color: Colors.black,
            fontFamily: AppFontStyles.urbanistFontFamily,
            fontSize: AppFontStyles.textFieldInputSize.sp,
            fontVariations: [AppFontStyles.boldFontVariation],
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.disabledGreyColor,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontSize: AppFontStyles.textFieldInputSize.sp,
              fontVariations: [AppFontStyles.regularFontVariation],
            ),
            labelText: widget.label,
            labelStyle: TextStyle(
              color: AppColors.hintTextBlack,
              fontFamily: AppFontStyles.urbanistFontFamily,
              fontSize: AppFontStyles.textFieldInputSize.sp,
              fontVariations: [AppFontStyles.regularFontVariation],
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.textFieldPrefixPaddingHorizontal.w,
                vertical: AppDimensions.textFieldPrefixPaddingVertical.h,
              ),
              child: widget.prefixIcon,
            ),
            prefixIconConstraints: BoxConstraints(),
            suffixIconConstraints: BoxConstraints(),
            suffixIcon: widget.isPasswordField
                ? Padding(
                    padding: EdgeInsets.only(
                        right: AppDimensions.dim7.w, top: AppDimensions.dim5.h),
                    child: IconButton(
                      icon: Image.asset(
                        _obscureText
                            ? 'assets/images/password_visibility_off.png'
                            : 'assets/images/password_visibility_on.png',
                        width: AppDimensions.dim18.w,
                        height: AppDimensions.dim18.h,
                        color: AppColors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radius_100.h),
              borderSide: BorderSide(
                color: widget.borderColor ?? Colors.transparent,
                width: 2.w,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radius_100.h),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.lightgray,
                width: AppDimensions.dim1.w,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radius_100.h),
              borderSide: BorderSide(
                color: widget.borderColor ?? Theme.of(context).primaryColor,
                width: 2.w,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppDimensions.textFieldPrefixPaddingHorizontal.w,
              vertical: AppDimensions.textFieldPrefixPaddingVertical.h,
            ),
          ),
        ),
      ),
    );
  }
}
