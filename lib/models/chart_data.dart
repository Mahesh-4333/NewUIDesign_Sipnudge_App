class ChartData {
  final String x;
  final double completionPercent;
  final double completionVolume;
  final DateTime date;
  
  final double loggedPercent;
  final double milkPercent;
  final double coffeePercent;
  final double teaPercent;
  final double juicePercent;
  final double mealPercent;
  final double bottlePercent;

  ChartData(
    this.x,
    this.completionPercent,
    this.completionVolume,
    this.date, {
    this.loggedPercent = 0.0,
    this.milkPercent = 0.0,
    this.coffeePercent = 0.0,
    this.teaPercent = 0.0,
    this.juicePercent = 0.0,
    this.mealPercent = 0.0,
    this.bottlePercent = 0.0,
  });
}
