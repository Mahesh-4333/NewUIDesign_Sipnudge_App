import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            // gradient: LinearGradient(
            //   colors: [
            //     AppColors.bottomSheetGradientStart,
            //     AppColors.bottomSheetGradientEnd,
            //   ],
            //   begin: Alignment.topCenter,
            //   end: Alignment.bottomCenter,
            // ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radius_20),
              topRight: Radius.circular(AppDimensions.radius_20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: AppDimensions.dim40.w,
                  height: AppDimensions.dim5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: AppColors.black),
                  title: Text(
                    'Gallery',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: AppFontStyles.fontSize_18.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.fontWeightVariation600],
                    ),
                  ),
                  onTap: () async {
                    final pickedFile =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      await _saveImageLocally(File(pickedFile.path));
                    }
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.black),
                  title: Text(
                    'Camera',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: AppFontStyles.fontSize_18.sp,
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      fontVariations: [AppFontStyles.fontWeightVariation600],
                    ),
                  ),
                  onTap: () async {
                    final pickedFile =
                        await _picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      await _saveImageLocally(File(pickedFile.path));
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
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
