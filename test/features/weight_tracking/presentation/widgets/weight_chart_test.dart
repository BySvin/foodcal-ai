import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/features/weight_tracking/domain/entities/weight_entry.dart';
import 'package:food_calorie_tracker/features/weight_tracking/presentation/widgets/weight_chart.dart';

WeightEntry _entry(String date, double weightKg) {
  return WeightEntry(id: 'uid-1_$date', userId: 'uid-1', weightKg: weightKg, loggedDate: date);
}

Future<void> _pumpChart(WidgetTester tester, List<WeightEntry> entries) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: WeightChart(entries: entries))),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a placeholder message with fewer than 2 entries', (tester) async {
    await _pumpChart(tester, [_entry('2026-08-04', 80)]);

    expect(find.text('Log at least 2 days to see a trend.'), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('shows a placeholder message with zero entries', (tester) async {
    await _pumpChart(tester, []);

    expect(find.text('Log at least 2 days to see a trend.'), findsOneWidget);
  });

  testWidgets('renders a line chart once there are 2 or more entries', (tester) async {
    await _pumpChart(tester, [
      _entry('2026-08-02', 81),
      _entry('2026-08-03', 80.5),
      _entry('2026-08-04', 80),
    ]);

    expect(find.text('Log at least 2 days to see a trend.'), findsNothing);
    // fl_chart's LineChart renders as a CustomPaint under the hood.
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
