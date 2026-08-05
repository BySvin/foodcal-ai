/// A `weight_logs/{uid}_{loggedDate}` entry — deterministic doc id means at
/// most one entry per user per day; re-logging the same day overwrites it.
class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.loggedDate,
    this.note,
  });

  final String id;
  final String userId;
  final double weightKg;
  final String loggedDate;
  final String? note;
}
