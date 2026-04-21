import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hydrify/constants/app_colors.dart';
import 'package:hydrify/constants/app_dimensions.dart';
import 'package:hydrify/constants/app_font_styles.dart';
import 'package:hydrify/constants/app_api_constants.dart';

class FoodScannerWidget extends StatefulWidget {
  const FoodScannerWidget({super.key});

  @override
  State<FoodScannerWidget> createState() => _FoodScannerWidgetState();
}

class _FoodScannerWidgetState extends State<FoodScannerWidget> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _weightController =
      TextEditingController(text: "250");
  bool _isAnalyzing = false;
  String? _waterContent;
  String? _waterVolume;
  String? _totalVolume;
  String? _dishName;
  String? _confidenceScore;
  String? _reasoning;
  int? _calories;
  num? _protein;
  num? _carbs;
  num? _fat;
  num? _sodium;
  num? _fiber;
  bool _showMacros = false;
  List<String> _details = [];
  String? _errorMessage;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo == null) return;

      setState(() {
        _image = File(photo.path);
        _isAnalyzing = true;
        _errorMessage = null;
        _dishName = null;
        _confidenceScore = null;
        _reasoning = null;
        _calories = null;
        _protein = null;
        _carbs = null;
        _fat = null;
        _sodium = null;
        _fiber = null;
        _details = [];
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

    final weight = _weightController.text.trim().isEmpty
        ? "250"
        : _weightController.text.trim();
    final bytes = await photo.readAsBytes();
    final content = [
      Content.multi([
        TextPart(
            "You are an expert nutritionist and food analysis AI for a smart hydration and macro-tracking app. \n\n"
            "Your task is to analyze the attached image of food, identify its components, and accurately estimate both the total water content and the full nutritional breakdown based on the provided total weight, food state, and user profile.\n\n"
            "User Input:\n"
            "- Total food weight: $weight grams.\n"
            "- Food state: Freshly cooked\n"
            "- Dietary preference: Pure Vegetarian\n"
            "- Fitness goal: Body Recomposition\n\n"
            "Follow these steps:\n"
            "1. Visual Identification: Carefully analyze the image to identify the main dish and all visible ingredients. Strictly adhere to the user's dietary preference when identifying ambiguous ingredients (e.g., if vegetarian, assume brown chunks are soya or paneer, not meat).\n"
            "2. Moisture Estimation: Determine the baseline water percentage, then adjust it based on the \"Food state\" (reducing it by 5-10% for leftovers/reheated food to account for evaporation and retrogradation).\n"
            "3. Hydration Calculation: Multiply the total weight by the final adjusted water percentage to find the total water content in milliliters (1g = 1ml).\n"
            "4. Nutritional Breakdown: Estimate the calories, protein, carbohydrates, fat, sodium, and dietary fiber for the total weight provided. Account for changes in caloric density due to moisture loss in the specified food state.\n\n"
            "You MUST return your response STRICTLY as a valid JSON object. Do not include any markdown formatting, code blocks, or conversational text outside the JSON. \n\n"
            "Use the following JSON schema:\n"
            "{\n"
            "  \"dish_name\": \"Name of the overall dish\",\n"
            "  \"visible_ingredients\": [\"ingredient 1\", \"ingredient 2\"],\n"
            "  \"dietary_type\": \"Confirmed dietary classification\",\n"
            "  \"hydration_data\": {\n"
            "    \"baseline_water_percentage\": 60,\n"
            "    \"adjusted_water_percentage\": 52,\n"
            "    \"total_water_ml\": 270\n"
            "  },\n"
            "  \"nutritional_estimates\": {\n"
            "    \"calories_kcal\": 900,\n"
            "    \"protein_g\": 28,\n"
            "    \"carbs_g\": 110,\n"
            "    \"fat_g\": 35,\n"
            "    \"sodium_mg\": 1700,\n"
            "    \"fiber_g\": 10\n"
            "  },\n"
            "  \"confidence_score\": \"High/Medium/Low\",\n"
            "  \"reasoning\": \"A brief explanation of the moisture adjustments and macro estimates based on the visual evidence, user dietary preference, and food state.\"\n"
            "}"),
        DataPart('image/jpeg', bytes),
      ])
    ];

    for (int i = 0; i < models.length; i++) {
      final modelName = models[i];
      try {
        debugPrint("Attempting analysis with: $modelName");
        final model = GenerativeModel(
          model: modelName,
          apiKey: AppApiConstants.geminiApiKey,
        );

        final response = await model.generateContent(content);
        final text = response.text;

        if (text != null) {
          _parseResponse(text);
          setState(() {
            _isAnalyzing = false;
          });
          return; // Success!
        } else {
          throw Exception("Empty response from AI");
        }
      } catch (e) {
        debugPrint("Gemini Error with $modelName: $e");
        final errorStr = e.toString().toLowerCase();

        bool isTransient = errorStr.contains('503') ||
            errorStr.contains('404') ||
            errorStr.contains('not found') ||
            errorStr.contains('unavailable') ||
            errorStr.contains('demand');

        if (isTransient && i < models.length - 1) {
          debugPrint("Retrying with next model...");
          continue;
        }

        setState(() {
          _errorMessage =
              "AI analysis failed. Please try again later or check your API key.";
          _isAnalyzing = false;
        });
        break;
      }
    }
  }

  Future<void> _listModels() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Debug: Available Models"),
        content: const SingleChildScrollView(
          child: Text(
              "Check console logs for a list of available models. If the error persists, the model might be unavailable for your key."),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close")),
        ],
      ),
    );
  }

  void _parseResponse(String text) {
    try {
      // Clean potential markdown tags if AI ignores instructions
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
        _details = List<String>.from(data['visible_ingredients'] ?? []);
        _waterContent = "${hydration['adjusted_water_percentage'] ?? hydration['baseline_water_percentage'] ?? 0}%";
        _waterVolume = "${hydration['total_water_ml'] ?? 0} ml";
        _totalVolume = "${_weightController.text} g";
        _confidenceScore = data['confidence_score'] ?? "Medium";
        _reasoning = data['reasoning'] ?? "";
        
        // Macros
        _calories = nutrition['calories_kcal'];
        _protein = nutrition['protein_g'];
        _carbs = nutrition['carbs_g'];
        _fat = nutrition['fat_g'];
        _sodium = nutrition['sodium_mg'];
        _fiber = nutrition['fiber_g'];
      });
    } catch (e) {
      debugPrint("JSON Parsing Error: $e");
      setState(() {
        _errorMessage =
            "Failed to parse AI response. Please ensure image is clear.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.defaultPadding.w),
      padding: EdgeInsets.all(AppDimensions.dim16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radius_12.r),
        border: Border.all(color: AppColors.greywith80.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weight Input Section
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Icon(Icons.scale_rounded,
                    size: 18.w, color: AppColors.bluegray),
                SizedBox(width: 8.w),
                Text(
                  "Total Food Weight (g):",
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.bluegray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    height: 36.h,
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blueWaterIntake),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(
                              color: AppColors.greywith80.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide:
                              BorderSide(color: AppColors.blueWaterIntake),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.greywith80.withOpacity(0.3)),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Image or Placeholder
              InkWell(
                onTap: _isAnalyzing ? null : _captureAndAnalyze,
                borderRadius: BorderRadius.circular(AppDimensions.radius_10.r),
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: AppColors.greywith80.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radius_10.r),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radius_10.r),
                    child: _image != null
                        ? Image.file(_image!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 32.w, color: AppColors.bluegray),
                              SizedBox(height: 4.h),
                              Text(
                                "Capture Food",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: AppColors.bluegray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              // Right Side: Details
              Expanded(
                child: InkWell(
                  onTap: _image == null
                      ? (_isAnalyzing ? null : _captureAndAnalyze)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dishName ?? "Food Analysis",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppColors.bluegray,
                          fontFamily: AppFontStyles.urbanistFontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      if (_isAnalyzing)
                        Container(
                          height: 60.h,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_errorMessage != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _errorMessage!,
                              style:
                                  TextStyle(fontSize: 11.sp, color: Colors.red),
                            ),
                            TextButton(
                              onPressed: _listModels,
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 30)),
                              child: const Text("Debug",
                                  style: TextStyle(fontSize: 10)),
                            ),
                          ],
                        )
                      else if (_waterContent == null)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.h),
                          child: Text(
                            "Capture image to see hydration details",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.bluegray.withOpacity(0.6),
                              fontFamily: AppFontStyles.urbanistFontFamily,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Water: ",
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.bluegray,
                                      fontWeight: FontWeight.w500,
                                      fontVariations: [
                                        AppFontStyles.semiBoldFontVariation
                                      ]),
                                ),
                                Text(
                                  "$_waterContent ",
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      color: AppColors.blueWaterIntake,
                                      fontWeight: FontWeight.bold,
                                      fontVariations: [
                                        AppFontStyles.semiBoldFontVariation
                                      ]),
                                ),
                                Text(
                                  "($_waterVolume)",
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color:
                                          AppColors.bluegray.withOpacity(0.7),
                                      fontVariations: [
                                        AppFontStyles.semiBoldFontVariation
                                      ]),
                                ),
                              ],
                            ),
                            if (_confidenceScore != null)
                              Padding(
                                padding: EdgeInsets.only(top: 2.h),
                                child: Text(
                                  "Confidence: $_confidenceScore",
                                  style: TextStyle(
                                      fontSize: 10.sp,
                                      color: _confidenceScore == "High"
                                          ? Colors.green
                                          : (_confidenceScore == "Medium"
                                              ? Colors.orange
                                              : Colors.red),
                                      fontWeight: FontWeight.w600,
                                      fontVariations: [
                                        AppFontStyles.semiBoldFontVariation
                                      ]),
                                ),
                              ),
                            SizedBox(height: 6.h),
                            ..._details.map((point) => Padding(
                                  padding: EdgeInsets.only(bottom: 2.h),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("• ",
                                          style: TextStyle(
                                              fontSize: 11.sp,
                                              color: AppColors.darkgray,
                                              fontVariations: [
                                                AppFontStyles
                                                    .semiBoldFontVariation
                                              ])),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: AppColors.bluegray,
                                            height: 1.1,
                                              fontVariations: [AppFontStyles.semiBoldFontVariation]
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            if (_reasoning != null && _reasoning!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Text(
                                  _reasoning!,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.bluegray.withOpacity(0.6),
                                      fontVariations: [AppFontStyles.semiBoldFontVariation]
                                  ),
                                  maxLines: 10
                                ),
                              ),
                            if (_calories != null)
                              Column(
                                children: [
                                  SizedBox(height: 8.h),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _showMacros = !_showMacros;
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Nutritional Insights",
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: AppColors.bluegray,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        Icon(
                                          _showMacros ? Icons.expand_less : Icons.expand_more,
                                          size: 16.w,
                                          color: AppColors.bluegray,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_showMacros)
                                    Padding(
                                      padding: EdgeInsets.only(top: 6.h),
                                      child: Wrap(
                                        spacing: 6.w,
                                        runSpacing: 4.h,
                                        children: [
                                          _macroChip("Calories", "${_calories}kcal"),
                                          _macroChip("Protein", "${_protein}g"),
                                          _macroChip("Carbs", "${_carbs}g"),
                                          _macroChip("Fat", "${_fat}g"),
                                          _macroChip("Fiber", "${_fiber}g"),
                                          _macroChip("Sodium", "${_sodium}mg"),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
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

  Widget _macroChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.blueWaterIntake.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.blueWaterIntake.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontSize: 9.sp, color: AppColors.bluegray, fontVariations: [AppFontStyles.semiBoldFontVariation]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 9.sp, color: AppColors.blueWaterIntake, fontVariations: [AppFontStyles.semiBoldFontVariation]),
          ),
        ],
      ),
    );
  }
}
