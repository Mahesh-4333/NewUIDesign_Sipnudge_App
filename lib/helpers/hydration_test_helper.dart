class HydrationTestHelper {
  // Generates a string that represents a "Perfect Day" (all slots met)
  // Format: "0/200/250 | 1/250/300 | ..."
  static String generatePerfectDayString() {
    return List.generate(7, (i) => "$i/250/300").join('|');
  }

  // Generates a string for a "Failed Day" (one slot missing)
  static String generateFailedDayString() {
    return "0/250/100|" + List.generate(6, (i) => "${i + 1}/250/300").join('|');
  }
}
