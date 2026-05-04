import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inner_shadow/flutter_inner_shadow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hydrify/constants/app_style.dart';
import 'package:hydrify/constants/assets_path.dart';
import 'package:hydrify/cubit/bottom_nav/bottom_nav_cubit.dart';
import 'package:hydrify/helpers/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/helpers/shared_pref_helper.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_api_constants.dart';
import 'package:hydrify/helpers/database_helper.dart';
import 'package:hydrify/models/food_scan_data.dart';
import 'package:fl_chart/fl_chart.dart';

class FoodScannerWidget extends StatefulWidget {
  const FoodScannerWidget({super.key});

  @override
  State<FoodScannerWidget> createState() => _FoodScannerWidgetState();
}

class _FoodScannerWidgetState extends State<FoodScannerWidget> {
  File? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  String? _errorMessage;

  // Food Data
  int? _currentScanId;
  String? _dishName;
  double _currentWeight = 100.0;
  double _baseWeight = 100.0;
  double _waterPercentage = 0.0;
  double _waterMl = 0.0;
  int _calories = 0;
  double _protein = 0.0;
  double _carbs = 0.0;
  double _fat = 0.0;
  double? _sodium;
  double? _fiber;
  String _confidenceScore = "0%";
  String _confidenceLevel = "NA";
  List<String> _ingredients = [];
  String? _reasoning;

  // Base values for recalculation
  double _baseWaterMl = 0.0;
  int _baseCalories = 0;
  double _baseProtein = 0.0;
  double _baseCarbs = 0.0;
  double _baseFat = 0.0;
  double? _baseSodium;
  double? _baseFiber;

  @override
  void initState() {
    super.initState();
    _loadTodayScan();
  }

  Future<void> _loadTodayScan() async {
    final scans = await DatabaseHelper().getAllFoodScans();
    if (scans.isNotEmpty) {
      final latest = FoodScanData.fromMap(scans.first);
      final now = DateTime.now();
      if (latest.timestamp.year == now.year &&
          latest.timestamp.month == now.month &&
          latest.timestamp.day == now.day) {
        setState(() {
          _currentScanId = latest.id;
          _dishName = latest.dishName;
          _currentWeight = latest.weightG;
          _baseWeight = latest.weightG;
          _waterPercentage = latest.waterPercentage;
          _waterMl = latest.waterContentMl;
          _calories = latest.caloriesKcal.toInt();
          _protein = latest.proteinG;
          _carbs = latest.carbsG;
          _fat = latest.fatG;
          _sodium = latest.sodiumMg;
          _fiber = latest.fiberG;
          _confidenceScore = latest.confidenceScore;
          _ingredients = latest.ingredients;
          _reasoning = latest.reasoning;
          if (latest.imageBase64 != null) {
            _imageBytes = base64Decode(latest.imageBase64!);
          } else if (latest.imagePath != null) {
            _image = File(latest.imagePath!);
          }

          // Set base values for future recalculations
          _baseWaterMl = _waterMl;
          _baseCalories = _calories;
          _baseProtein = _protein;
          _baseCarbs = _carbs;
          _baseFat = _fat;
          _baseSodium = _sodium;
          _baseFiber = _fiber;
          _baseWeight = _currentWeight;

          _updateConfidenceLevel(_confidenceScore);
        });
      }
    }
  }

  void _updateConfidenceLevel(String score) {
    if (score.contains('%')) {
      final val = double.tryParse(score.replaceAll('%', '')) ?? 0;
      if (val > 80)
        _confidenceLevel = "High";
      else if (val > 50)
        _confidenceLevel = "Medium";
      else
        _confidenceLevel = "Low";
    } else {
      _confidenceLevel = score;
    }
  }

  void _recalculate(double newWeight) {
    if (_baseWeight == 0) return;
    final ratio = newWeight / _baseWeight;
    setState(() {
      _currentWeight = newWeight;
      _waterMl = _baseWaterMl * ratio;
      _calories = (_baseCalories * ratio).toInt();
      _protein = _baseProtein * ratio;
      _carbs = _baseCarbs * ratio;
      _fat = _baseFat * ratio;
      if (_baseSodium != null) _sodium = _baseSodium! * ratio;
      if (_baseFiber != null) _fiber = _baseFiber! * ratio;
    });
  }

  Future<void> _captureAndAnalyze() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      setState(() {
        _image = File(photo.path);
        _imageBytes = bytes;
        _isAnalyzing = true;
        _errorMessage = null;
        _currentScanId = null;
      });

      await _analyzeWithGemini(photo);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = "Failed to capture or analyze image.";
      });
    }
  }

  Future<void> _analyzeWithGemini(XFile photo) async {
    final List<String> models = [
      'gemini-3.0-flash',
      'gemini-2.5-pro',
      'gemini-2.5-flash',
    ];

    final bytes = await photo.readAsBytes();
    final content = [
      Content.multi([
        TextPart(
            "You are an expert nutritionist. Analyze this food image and provide nutritional info for 100g portion.\n\n"
            "Use the following JSON schema:\n"
            "{\n"
            "  \"dish_name\": \"Name\",\n"
            "  \"visible_ingredients\": [\"item 1\", \"item 2\"],\n"
            "  \"hydration_data\": {\n"
            "    \"water_percentage\": 65,\n"
            "    \"total_water_ml\": 65\n"
            "  },\n"
            "  \"nutritional_estimates\": {\n"
            "    \"calories_kcal\": 250,\n"
            "    \"protein_g\": 15,\n"
            "    \"carbs_g\": 30,\n"
            "    \"fat_g\": 10,\n"
            "    \"sodium_mg\": 400,\n"
            "    \"fiber_g\": 5\n"
            "  },\n"
            "  \"confidence_score\": \"85%\",\n"
            "  \"reasoning\": \"A brief explanation.\"\n"
            "}"),
        DataPart('image/jpeg', bytes),
      ])
    ];

    for (int i = 0; i < models.length; i++) {
      try {
        final model = GenerativeModel(
          model: models[i],
          apiKey: AppApiConstants.geminiApiKey,
        );

        final response = await model.generateContent(content);
        final text = response.text;

        if (text != null) {
          _parseResponse(text);
          setState(() {
            _isAnalyzing = false;
          });
          await _saveToDb();
          return;
        }
      } catch (e) {
        if (i == models.length - 1) {
          setState(() {
            _errorMessage = "AI analysis failed.";
            _isAnalyzing = false;
          });
        }
        Console.log(tag: "food_scanner_error", value: e.toString());
      }
    }
  }

  void _parseResponse(String text) {
    try {
      String jsonClean = text.trim();
      if (jsonClean.contains('```json')) {
        jsonClean = jsonClean.split('```json').last.split('```').first.trim();
      } else if (jsonClean.contains('```')) {
        jsonClean = jsonClean.split('```').last.split('```').first.trim();
      }

      final data = jsonDecode(jsonClean);
      final hydration = data['hydration_data'] ?? {};
      final nutrition = data['nutritional_estimates'] ?? {};

      setState(() {
        _dishName = data['dish_name'] ?? "Unknown Dish";
        _ingredients = List<String>.from(data['visible_ingredients'] ?? []);
        _waterPercentage = (hydration['water_percentage'] ?? 0).toDouble();
        _waterMl = (hydration['total_water_ml'] ?? 0).toDouble();
        _confidenceScore = data['confidence_score'] ?? "70%";
        _reasoning = data['reasoning'] ?? "";

        _calories = (nutrition['calories_kcal'] ?? 0).toInt();
        _protein = (nutrition['protein_g'] ?? 0).toDouble();
        _carbs = (nutrition['carbs_g'] ?? 0).toDouble();
        _fat = (nutrition['fat_g'] ?? 0).toDouble();
        _sodium = nutrition['sodium_mg'] != null
            ? (nutrition['sodium_mg']).toDouble()
            : null;
        _fiber = nutrition['fiber_g'] != null
            ? (nutrition['fiber_g']).toDouble()
            : null;

        _baseWaterMl = _waterMl;
        _baseCalories = _calories;
        _baseProtein = _protein;
        _baseCarbs = _carbs;
        _baseFat = _fat;
        _baseSodium = _sodium;
        _baseFiber = _fiber;
        _baseWeight = 100.0;
        _currentWeight = 100.0;

        _updateConfidenceLevel(_confidenceScore);
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to parse AI response.";
      });
    }
  }

  Future<void> _saveToDb() async {
    if (_dishName == null) return;
    try {
      final scan = FoodScanData(
        id: _currentScanId,
        dishName: _dishName!,
        imagePath: _image?.path,
        weightG: _currentWeight,
        waterContentMl: _waterMl,
        waterPercentage: _waterPercentage,
        caloriesKcal: _calories.toDouble(),
        proteinG: _protein,
        carbsG: _carbs,
        fatG: _fat,
        sodiumMg: _sodium,
        fiberG: _fiber,
        confidenceScore: _confidenceScore,
        ingredients: _ingredients,
        reasoning: _reasoning,
        imageBase64: _imageBytes != null ? base64Encode(_imageBytes!) : null,
        timestamp: DateTime.now(),
      );
      final id = await DatabaseHelper().insertFoodScan(scan.toMap());
      setState(() {
        _currentScanId = id;
      });
      await SharedPrefsHelper.setAiHydrationGoalShown(true);
      Console.log(
          tag: 'FoodScanner', value: '[DB] Food scan saved: ${scan.dishName}');
    } catch (e, st) {
      Console.log(tag: 'FoodScanner', value: '[DB] _saveToDb failed: $e\n$st');
    }
  }

  void _showWeightPicker() async {
    context.read<BottomNavCubit>().hideBar();

    // Calculate initial item index (interval of 50)
    final int initialItem = ((_currentWeight / 50).round() - 1).clamp(0, 2999);
    final FixedExtentScrollController scrollController =
        FixedExtentScrollController(initialItem: initialItem);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (context) {
        return Container(
          height: 350.h,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            children: [
              // Header with Done button on top right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // Spacer for centering title
                  Text(
                    "Select Weight (g)",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily,
                      color: AppColors.bluegray,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _saveToDb();
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Done",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontVariations: [AppFontStyles.boldFontVariation],
                        color: AppColors.blueWaterIntake,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Cupertino-style picker with highlight
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Highlight bar
                    Container(
                      height: 50.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.blueWaterIntake.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    ListWheelScrollView.useDelegate(
                      controller: scrollController,
                      itemExtent: 50.h,
                      perspective: 0.005,
                      diameterRatio: 1.5,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        _recalculate(((index + 1) * 50).toDouble());
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          return Center(
                            child: Text(
                              "${(index + 1) * 50} g",
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontVariations: [
                                  AppFontStyles.boldFontVariation
                                ],
                                color: AppColors.bluegray,
                              ),
                            ),
                          );
                        },
                        childCount: 3000,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
    context.read<BottomNavCubit>().showBar();
  }

  @override
  Widget build(BuildContext context) {
    bool isLoaded = _dishName != null;

    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            blurRadius: AppDimensions.radius_4,
            color: AppColors.black.withAlpha((0.25 * 255).round()),
            offset: Offset(
              AppDimensions.dim2,
              AppDimensions.dim2,
            ),
          )
        ],
      ),
      child: Stack(
        children: [
          // SizedBox(height: 200.h),
          // Background Image
          // if (_imageBytes != null || _image != null)
          //   Positioned.fill(
          //     child: _imageBytes != null
          //       ? Image.memory(
          //           _imageBytes!,
          //           fit: BoxFit.cover,
          //           color: Colors.black.withOpacity(0.1),
          //           colorBlendMode: BlendMode.darken,
          //         )
          //       : Image.file(
          //           _image!,
          //           fit: BoxFit.cover,
          //           color: Colors.black.withOpacity(0.1),
          //           colorBlendMode: BlendMode.darken,
          //         ),
          //   ),

          Positioned.fill(
            left: 0,
            right: 0,
            bottom: isLoaded ? 120 : -300,
            child: Image.asset(
              AssetsPath.foodImage,
              fit: BoxFit.cover,
            ),
          ),

          // Foreground Content
          Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Column(
                    children: [
                      // Confidence Badge
                      if (_confidenceScore != '0%') _buildConfidenceBadge(),
                      SizedBox(height: 10.h),

                      // Title
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        child: Text(
                          "Snap food pics for quick\nAI-driven nutrition facts",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: _image != null
                                ? const Color(0xFF456173)
                                : AppColors.bluegray,
                            fontVariations: [AppFontStyles.boldFontVariation],
                            height: 1.2,
                            fontFamily: AppFontStyles.urbanistFontFamily,
                          ),
                        ),
                      ),
                      // Scanner Card
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: (_imageBytes != null || _image != null)
                              ? Colors.white.withOpacity(0.4)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            if (_imageBytes == null && _image == null)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                          ],
                          border: Border.all(
                              color: AppColors.greyColorText1
                                  .withValues(alpha: 0.4),
                              width: 1.9),
                        ),
                        child: Column(
                          children: [
                            _buildImageFrame(),
                            if (_imageBytes == null && _image == null) ...[
                              SizedBox(height: 16.h),
                              Text(
                                "Click to scan or add food item",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: const Color(0xFF456173),
                                  fontVariations: [
                                    AppFontStyles.semiBoldFontVariation
                                  ],
                                  fontFamily: AppFontStyles.urbanistFontFamily,
                                ),
                              )
                            ],
                          ],
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        SizedBox(height: 12.h),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.red,
                            fontVariations: [AppFontStyles.boldFontVariation],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isLoaded) ...[
                  SizedBox(height: 24.h),
                  _buildFoodDetails(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff00d0ff),
            Color(0xff00d0ff),
            Color(0xff00d0ff),
            Color(0xff00d0ff),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        image: DecorationImage(image: AssetImage(AssetsPath.confidenceBadge)),
        borderRadius: BorderRadius.circular(50.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AssetsPath.confidence,
            width: 15.sp,
            height: 15.sp,
            color: const Color(0xFF0056D2),
          ),
          SizedBox(width: 14.w),
          Text(
            "$_confidenceScore CONFIDENCE",
            style: TextStyle(
              fontSize: 15.sp,
              fontVariations: [AppFontStyles.boldFontVariation],
              fontFamily: AppFontStyles.museoModernoFontFamily,
              color: AppColors.darkgray,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFrame() {
    return InkWell(
      onTap: _isAnalyzing ? null : _captureAndAnalyze,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 195.w,
            height: 195.w,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: Colors.white.withValues(alpha: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25.r),
            child: _imageBytes != null
                ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                : _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : Container(color: Colors.white),
            ),
          ),
          // Scanner Corners
          SizedBox(
            width: 220.w,
            height: 220.w,
            child: CustomPaint(
                painter: ScannerCornersPainter(
                    color: (_imageBytes != null || _image != null)
                        ? Colors.white
                        : Colors.grey.withOpacity(0.4))),
          ),
          if (_imageBytes == null && _image == null)
            Image.asset(AssetsPath.camera_food_scn, width: 50.sp, height: 50.sp),
          if (_isAnalyzing)
            const CircularProgressIndicator(color: AppColors.blueWaterIntake),
        ],
      ),
    );
  }

  Widget _buildFoodDetails() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(20.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _dishName ?? "",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    color: AppColors.bluegray,
                    fontFamily: AppFontStyles.urbanistFontFamily,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWeightSelector(),
                  SizedBox(height: 8.h),
                  _buildCaloriesBadge(),
                ],
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Gauge Section
          Center(
            child: Stack(
              children: [
                SizedBox(
                  height: 100.h,
                ),
                SizedBox(
                  width: 160.w,
                  height: 80.w,
                  child: CustomPaint(
                    painter: SemiCircleGaugePainter(_waterPercentage),
                  ),
                ),
                SizedBox(height: 8.h),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 35.h,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${_waterMl.toInt()}mL",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          color: AppColors.bluegray,
                        ),
                      ),
                      Text(
                        "WATER\nContent",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontVariations: [AppFontStyles.boldFontVariation],
                          color: AppColors.bluegray.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 24.h),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoColumn(
                  "Water: ",
                  "${_waterPercentage.toInt()}% (${_waterMl.toInt()}ml)",
                  _ingredients,
                  "Item Contains",
                ),
              ),
              Container(
                  width: 1, height: 100.h, color: Colors.grey.withOpacity(0.2)),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildInfoColumn(
                  "",
                  "",
                  _ingredients.reversed.take(3).toList(),
                  // Just for design variety
                  "Item Contains",
                  valueColor: _confidenceLevel == "High"
                      ? Colors.green
                      : (_confidenceLevel == "Medium"
                          ? Colors.orange
                          : Colors.red),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Macro Rings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroRing("Carbs", _carbs, Color(0xffFFB53A)),
              _buildMacroRing("Protein", _protein, Colors.blueAccent),
              _buildMacroRing("Fat", _fat, Color(0xffB084D1)),
            ],
          ),

          if (_reasoning != null) ...[
            SizedBox(height: 20.h),
            Text(
              _reasoning!,
              style: TextStyle(
                  fontSize: 10.sp,
                  fontStyle: FontStyle.italic,
                  color: AppColors.bluegray,
                  fontVariations: [AppFontStyles.semiBoldFontVariation]),
            ),
          ],

          SizedBox(height: 20.h),
          Center(
            child: Text(
              "Calculated based on ${_currentWeight.toInt()}g portion size",
              style: TextStyle(
                  fontSize: 10.sp,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                  fontVariations: [AppFontStyles.semiBoldFontVariation]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSelector() {
    return InkWell(
      onTap: _showWeightPicker,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFFD4E9FF),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Text(
              "${_currentWeight.toInt()} g",
              style: TextStyle(
                fontSize: 12.sp,
                fontVariations: [AppFontStyles.boldFontVariation],
                color: AppColors.blueWaterIntake,
              ),
            ),
            Icon(Icons.unfold_more,
                size: 14.sp, color: AppColors.blueWaterIntake),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFD4E9FF),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        "$_calories kcal",
        style: TextStyle(
          fontSize: 12.sp,
          fontVariations: [AppFontStyles.boldFontVariation],
          color: AppColors.blueWaterIntake,
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
      String label, String value, List<String> items, String subHeader,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: label,
                  style: TextStyle(
                      color: AppColors.bluegray,
                      fontSize: 12.sp,
                      fontVariations: [AppFontStyles.boldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily)),
              TextSpan(
                  text: value,
                  style: TextStyle(
                      color: valueColor ?? AppColors.blueWaterIntake,
                      fontSize: 12.sp,
                      fontVariations: [AppFontStyles.extraBoldFontVariation],
                      fontFamily: AppFontStyles.urbanistFontFamily)),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(subHeader,
            style: TextStyle(
                color: AppColors.bluegray,
                fontSize: 12.sp,
                fontVariations: [AppFontStyles.boldFontVariation])),
        SizedBox(height: 4.h),
        ...items.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text("• $item",
                  style: TextStyle(
                      color: AppColors.bluegray,
                      fontSize: 11.sp,
                      fontVariations: [AppFontStyles.semiBoldFontVariation])),
            )),
      ],
    );
  }

  Widget _buildMacroRing(String label, double value, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey,
                fontVariations: [AppFontStyles.boldFontVariation])),
        SizedBox(height: 4.h),
        SizedBox(
          width: 50.w,
          height: 50.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 18.w,
                  startDegreeOffset: 270,
                  sections: [
                    PieChartSectionData(
                      color: color,
                      value: value,
                      radius: 6.w,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      color: color.withOpacity(0.1),
                      value: 100 - value,
                      radius: 6.w,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Text(
                "${value.toInt()}%",
                style: TextStyle(
                    fontSize: 11.sp,
                    fontVariations: [AppFontStyles.boldFontVariation],
                    color: AppColors.bluegray),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ScannerCornersPainter extends CustomPainter {
  final Color color;

  ScannerCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const length = 40.0;
    const offset = 10.0;
    const cornerRadius = 15.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(offset, offset + length)
        ..lineTo(offset, offset + cornerRadius)
        ..arcTo(
            Rect.fromLTWH(offset, offset, cornerRadius * 2, cornerRadius * 2),
            pi,
            pi / 2,
            false)
        ..lineTo(offset + length, offset),
      paint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - offset - length, offset)
        ..lineTo(size.width - offset - cornerRadius, offset)
        ..arcTo(
            Rect.fromLTWH(size.width - offset - cornerRadius * 2, offset,
                cornerRadius * 2, cornerRadius * 2),
            -pi / 2,
            pi / 2,
            false)
        ..lineTo(size.width - offset, offset + length),
      paint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(offset + length, size.height - offset)
        ..lineTo(offset + cornerRadius, size.height - offset)
        ..arcTo(
            Rect.fromLTWH(offset, size.height - offset - cornerRadius * 2,
                cornerRadius * 2, cornerRadius * 2),
            pi / 2,
            pi / 2,
            false)
        ..lineTo(offset, size.height - offset - length),
      paint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - offset, size.height - offset - length)
        ..lineTo(size.width - offset, size.height - offset - cornerRadius)
        ..arcTo(
            Rect.fromLTWH(
                size.width - offset - cornerRadius * 2,
                size.height - offset - cornerRadius * 2,
                cornerRadius * 2,
                cornerRadius * 2),
            0,
            pi / 2,
            false)
        ..lineTo(size.width - offset - length, size.height - offset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SemiCircleGaugePainter extends CustomPainter {
  final double percentage;

  SemiCircleGaugePainter(this.percentage);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;
    const strokeWidth = 12.0;

    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF369FFF), Color(0xFF6FB9FF)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      pi,
      pi,
      false,
      bgPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      pi,
      pi * (percentage / 100),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SemiCircleGaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
