class WaterConsumptionData {
  final DateTime date;
  final double consumedVolume;
  final double completionPercentage;

  WaterConsumptionData({
    required this.date,
    required this.consumedVolume,
    this.completionPercentage = 0,
  });
}
