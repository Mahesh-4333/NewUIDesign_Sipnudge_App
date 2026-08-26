import 'dart:convert';

class FoodScanData {
  final int? id;
  final String? serverId;
  final String dishName;
  final String? foodKey;
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
    this.serverId,
    required this.dishName,
    this.foodKey,
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
      'food_key': foodKey ?? 'Meal',
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
    final dish = (map['dish_name'] ?? map['dishName'] ?? '').toString();
    String? rawKey = map['food_key'] ?? map['foodKey'] ?? map['types'] ?? map['type'];
    String resolvedKey = 'Meal';

    if (rawKey != null && rawKey.toString().trim().isNotEmpty) {
      final lower = rawKey.toString().trim().toLowerCase();
      if (lower == 'water') {
        resolvedKey = 'Water';
      } else if (lower == 'juice') {
        resolvedKey = 'Juice';
      } else if (lower == 'milk') {
        resolvedKey = 'Milk';
      } else if (lower == 'coffee') {
        resolvedKey = 'Coffee';
      } else if (lower == 'tea') {
        resolvedKey = 'Tea';
      } else if (lower == 'meal') {
        resolvedKey = 'Meal';
      } else {
        resolvedKey = rawKey.toString().trim();
      }
    } else if (dish.isNotEmpty) {
      // Only infer from dish name if food_key is completely missing
      final dLower = dish.toLowerCase();
      if (dLower.contains('water')) {
        resolvedKey = 'Water';
      } else if (dLower.contains('coffee') ||
          dLower.contains('latte') ||
          dLower.contains('cappuccino') ||
          dLower.contains('espresso') ||
          dLower.contains('mocha')) {
        resolvedKey = 'Coffee';
      } else if (dLower.contains('tea') ||
          dLower.contains('chai') ||
          dLower.contains('matcha')) {
        resolvedKey = 'Tea';
      } else if (dLower.contains('milk') ||
          dLower.contains('shake') ||
          dLower.contains('lassi') ||
          dLower.contains('smoothie') ||
          dLower.contains('buttermilk') ||
          dLower.contains('chaas')) {
        resolvedKey = 'Milk';
      } else if (dLower.contains('juice') ||
          dLower.contains('lemonade') ||
          dLower.contains('soda') ||
          dLower.contains('drink') ||
          dLower.contains('mojito') ||
          dLower.contains('squash')) {
        resolvedKey = 'Juice';
      }
    }

    return FoodScanData(
      id: map['id'] is int ? map['id'] : null,
      serverId: map['_id']?.toString() ??
          map['scanId']?.toString() ??
          (map['id'] is String ? map['id'] : null),
      dishName: dish,
      foodKey: resolvedKey,
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
