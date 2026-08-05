/// A `water_logs/{uid}_{date}` entry — one aggregate document per user per
/// day. When no doc exists yet for a day, callers construct a default
/// (`totalMl: 0`, `goalMl` from the user's onboarding target) rather than
/// treating it as an error.
class WaterDay {
  const WaterDay({
    required this.date,
    required this.totalMl,
    required this.goalMl,
    this.lastAddedMl,
  });

  final String date;
  final int totalMl;
  final int goalMl;

  /// The amount of the most recent add, if any — enables a one-step undo.
  /// Cleared after an undo, so undo only ever reverts the single latest add.
  final int? lastAddedMl;

  double get progress => goalMl <= 0 ? 0 : totalMl / goalMl;

  WaterDay copyWith({int? totalMl, int? goalMl, int? lastAddedMl}) {
    return WaterDay(
      date: date,
      totalMl: totalMl ?? this.totalMl,
      goalMl: goalMl ?? this.goalMl,
      lastAddedMl: lastAddedMl ?? this.lastAddedMl,
    );
  }
}
