import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day currently being viewed — shared across Dashboard, Log, History,
/// and Water/Weight quick views. Defaults to today.
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
