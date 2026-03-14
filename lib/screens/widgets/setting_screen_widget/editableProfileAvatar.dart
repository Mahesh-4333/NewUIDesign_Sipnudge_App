import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/helpers/dialog_manager_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class EditableProfileAvatar extends StatefulWidget {
  const EditableProfileAvatar({super.key});

  @override
  State<EditableProfileAvatar> createState() => _EditableProfileAvatarState();
}

class _EditableProfileAvatarState extends State<EditableProfileAvatar> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  static const String _imagePathKey = 'profile_image_path';

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_imagePathKey);
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        _selectedImage = File(savedPath);
      });
    }
  }

  Future<void> _saveImageLocally(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final filename = path.basename(image.path);
    final savedImage = await image.copy('${directory.path}/$filename');

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_imagePathKey, savedImage.path);

    setState(() {
      _selectedImage = savedImage;
    });
  }

  Future<void> _pickImage() async {
    await DialogManager().showTrackedModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.dim20.w,
              vertical: AppDimensions.dim16.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radius_30.r),
              topRight: Radius.circular(AppDimensions.radius_30.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: AppDimensions.dim40.w,
                height: AppDimensions.dim4.h,
                decoration: BoxDecoration(
                  color: AppColors.lavenderPinocchio,
                  borderRadius: BorderRadius.circular(AppDimensions.radius_2.r),
                ),
              ),
              SizedBox(height: AppDimensions.dim20.h),

              Text(
                "Profile Photo",
                style: TextStyle(
                  color: AppColors.bleachedCedar,
                  fontSize: 20.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.fontWeightVariation600],
                ),
              ),
              SizedBox(height: 4.h),

              Text(
                "Choose a profile picture from your device",
                style: TextStyle(
                  color: AppColors.greyColorText1,
                  fontSize: 15.sp,
                  fontFamily: AppFontStyles.urbanistFontFamily,
                  fontVariations: [AppFontStyles.semiBoldFontVariation],
                ),
              ),
              SizedBox(height: AppDimensions.dim24.h),

              // Photo Gallery Option
              _buildPickerOption(
                icon: AssetsPath.gallery,
                title: "Photo Gallery",
                subtitle: "Choose from existing photos",
                onTap: () async {
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    await _saveImageLocally(File(pickedFile.path));
                  }
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: AppDimensions.dim16.h),

              // Take Photo Option
              _buildPickerOption(
                icon: AssetsPath.camera,
                title: "Take Photo",
                subtitle: "Use camera to capture new",
                onTap: () async {
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    await _saveImageLocally(File(pickedFile.path));
                  }
                  Navigator.pop(context);
                },
              ),
              SizedBox(height: AppDimensions.dim32.h),

              // Cancel Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(vertical: AppDimensions.dim14.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xff1E69B3),
                        Color(0xff3B82F6),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radius_30.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightBlue400.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: AppFontStyles.fontSize_18.sp,
                        fontFamily: AppFontStyles.urbanistFontFamily,
                        fontVariations: [AppFontStyles.fontWeightVariation600],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.dim16.h),
            ],
          ),
        );
      },
    );

    context.read<BottomNavCubit>().showBar();
  }

  Widget _buildPickerOption({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radius_50.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
          border:
              Border.all(color: AppColors.lavenderPinocchio.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Image.asset(icon, width: 50.sp, height: 50.sp,),
            SizedBox(width: 40.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.bleachedCedar,
                      fontSize: 20.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.fontWeightVariation600],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.steelblue,
                      fontSize: 13.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.greyColorText1, size: 24.sp),
            SizedBox(width: AppDimensions.dim4.w),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<BottomNavCubit>().hideBar();
        _pickImage();
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0x001f436d).withOpacity(0.40),
              blurRadius: AppDimensions.radius_6.r,
              offset: Offset(0, AppDimensions.radius_4.r),
            ),
          ],
        ),
        child: CircleAvatar(
          radius: AppDimensions.dim30.r,
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.dim70.r),
            child: _selectedImage != null
                ? Image.file(
                    _selectedImage!,
                    width: AppDimensions.dim70.w,
                    height: AppDimensions.dim70.h,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/person_icon_1.png',
                    width: AppDimensions.dim70.w,
                    height: AppDimensions.dim70.h,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      ),
    );
  }
}
