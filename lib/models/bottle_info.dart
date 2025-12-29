class BottleInfo {
  final String color;
  final String name;
  final String imagePath;
  final String material;
  final String description;
  static const double capacity = 650; // Fixed capacity in ml
  final double currentWater; // in ml - dynamic from home screen
  final int waterPercentage; // in % - dynamic from home screen

  BottleInfo({
    required this.color,
    required this.name,
    required this.imagePath,
    required this.material,
    required this.description,
    required this.currentWater,
    required this.waterPercentage,
  });

  // Get bottle details by color with dynamic water data
  static BottleInfo getByColor(
    String color, {
    required double currentWater,
    required int waterPercentage,
  }) {
    switch (color.toLowerCase()) {
      case 'black':
        return BottleInfo(
          color: 'Black',
          name: 'Midnight Edition',
          imagePath: 'assets/images/black_bottle_image.png',
          material: 'Stainless Steel',
          description: 'Premium black bottle with sleek design',
          currentWater: currentWater,
          waterPercentage: waterPercentage,
        );
      case 'gray':
        return BottleInfo(
          color: 'Gray',
          name: 'Classic Gray',
          imagePath: 'assets/images/gray_bottle_image.png',
          material: 'Aluminum',
          description: 'Lightweight and durable gray bottle',
          currentWater: currentWater,
          waterPercentage: waterPercentage,
        );
      case 'green':
        return BottleInfo(
          color: 'Green',
          name: 'Eco Green',
          imagePath: 'assets/images/green_bottle_image.png',
          material: 'Recycled Plastic',
          description: 'Environmentally friendly green bottle',
          currentWater: currentWater,
          waterPercentage: waterPercentage,
        );
      case 'purple':
      default:
        return BottleInfo(
          color: 'Purple',
          name: 'Royal Purple',
          imagePath: 'assets/images/purple_bottle_image.png',
          material: 'BPA-Free Plastic',
          description: 'Vibrant purple bottle for daily hydration',
          currentWater: currentWater,
          waterPercentage: waterPercentage,
        );
    }
  }

  // Helper method to create a copy with updated water data
  BottleInfo copyWith({
    double? currentWater,
    int? waterPercentage,
  }) {
    return BottleInfo(
      color: this.color,
      name: this.name,
      imagePath: this.imagePath,
      material: this.material,
      description: this.description,
      currentWater: currentWater ?? this.currentWater,
      waterPercentage: waterPercentage ?? this.waterPercentage,
    );
  }

  // Formatted text widgets
  String get currentWaterText => "${currentWater.toStringAsFixed(0)} ml";
  String get waterPercentageText => "$waterPercentage%";
}
