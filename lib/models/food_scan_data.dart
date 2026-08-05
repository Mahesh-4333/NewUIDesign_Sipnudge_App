import 'dart:convert';

class FoodScanData {
  final int? id;
  final String dishName;
  final String? imagePath;
  final String? imageBase64;
  final double weightG;
  final double waterContentMl;
  final double waterPercentage;
  final double caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? sodiumMg;
  final double? fiberG;
  final String confidenceScore;
  final List<String> ingredients;
  final String? reasoning;
  final DateTime timestamp;

  FoodScanData({
    this.id,
    required this.dishName,
    this.imagePath,
    this.imageBase64,
    required this.weightG,
    required this.waterContentMl,
    required this.waterPercentage,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.sodiumMg,
    this.fiberG,
    required this.confidenceScore,
    required this.ingredients,
    this.reasoning,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'dish_name': dishName,
      'image_path': imagePath,
      'image_base64': imageBase64,
      'weight_g': weightG,
      'water_content_ml': waterContentMl,
      'water_percentage': waterPercentage,
      'calories_kcal': caloriesKcal,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'sodium_mg': sodiumMg,
      'fiber_g': fiberG,
      'confidence_score': confidenceScore,
      'ingredients': jsonEncode(ingredients),
      'reasoning': reasoning,
      'timestamp': timestamp.toIso8601String(),
    };
    // Only include id when updating an existing record (non-null id)
    if (id != null) map['id'] = id;
    return map;
  }

  factory FoodScanData.fromMap(Map<String, dynamic> map) {
    return FoodScanData(
      id: map['id'],
      dishName: map['dish_name'] ?? map['dishName'] ?? '',
      imagePath: map['image_path'] ?? map['imagePath'],
      imageBase64: map['image_base64'] ?? map['imageBase64'],
      weightG: ((map['weight_g'] ?? map['weightG'] ?? 0) as num).toDouble(),
      waterContentMl: ((map['water_content_ml'] ?? map['waterContentMl'] ?? 0) as num).toDouble(),
      waterPercentage: ((map['water_percentage'] ?? map['waterPercentage'] ?? 0) as num).toDouble(),
      caloriesKcal: ((map['calories_kcal'] ?? map['caloriesKcal'] ?? 0) as num).toDouble(),
      proteinG: ((map['protein_g'] ?? map['proteinG'] ?? 0) as num).toDouble(),
      carbsG: ((map['carbs_g'] ?? map['carbsG'] ?? 0) as num).toDouble(),
      fatG: ((map['fat_g'] ?? map['fatG'] ?? 0) as num).toDouble(),
      sodiumMg: (map['sodium_mg'] ?? map['sodiumMg']) != null
          ? ((map['sodium_mg'] ?? map['sodiumMg']) as num).toDouble()
          : null,
      fiberG: (map['fiber_g'] ?? map['fiberG']) != null
          ? ((map['fiber_g'] ?? map['fiberG']) as num).toDouble()
          : null,
      confidenceScore: map['confidence_score'] ?? map['confidenceScore'] ?? '',
      ingredients: map['ingredients'] is String
          ? List<String>.from(jsonDecode(map['ingredients']))
          : List<String>.from(map['ingredients'] ?? []),
      reasoning: map['reasoning'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}
