import 'package:intl/intl.dart';

/// Date helpers centered on the 'yyyy-MM-dd' day-bucket string used as the
/// Firestore query key for food_logs/weight_logs/water_logs.
class AppDateUtils {
  const AppDateUtils._();

  static final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');

  static String toDayKey(DateTime date) => _dayFormat.format(date);

  static DateTime fromDayKey(String dayKey) => _dayFormat.parse(dayKey);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static DateTime addDays(DateTime date, int days) =>
      startOfDay(date).add(Duration(days: days));
}
