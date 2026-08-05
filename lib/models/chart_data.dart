class ChartData {
  final String x;
  final double completionPercent;
  final double completionVolume;
  final DateTime date;
  
  final double loggedPercent;
  final double milkPercent;
  final double coffeePercent;
  final double bottlePercent;

  ChartData(
    this.x,
    this.completionPercent,
    this.completionVolume,
    this.date, {
    this.loggedPercent = 0.0,
    this.milkPercent = 0.0,
    this.coffeePercent = 0.0,
    this.bottlePercent = 0.0,
  });
}
