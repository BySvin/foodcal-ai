import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:food_calorie_tracker/core/providers/firebase_providers.dart';
import 'package:food_calorie_tracker/features/water_tracker/presentation/widgets/water_tracker_card.dart';

Future<void> _pumpCard(WidgetTester tester, {List<Override> extraOverrides = const []}) async {
  final mockAuth = MockFirebaseAuth(
    signedIn: true,
    mockUser: MockUser(uid: 'uid-1', email: 'a@example.com'),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        ...extraOverrides,
      ],
      child: MaterialApp(
        home: Scaffold(body: WaterTrackerCard(date: DateTime(2026, 8, 4))),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows 0 / default goal when nothing logged yet', (tester) async {
    await _pumpCard(tester);

    expect(find.text('0 / 2000ml'), findsOneWidget);
    expect(find.text('+250 ml'), findsOneWidget);
    expect(find.text('+500 ml'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.textContaining('Undo'), findsNothing);
  });

  testWidgets('tapping a quick-add button logs water and shows undo', (tester) async {
    await _pumpCard(tester);

    await tester.tap(find.text('+250 ml'));
    await tester.pumpAndSettle();

    expect(find.text('250 / 2000ml'), findsOneWidget);
    expect(find.text('Undo +250 ml'), findsOneWidget);
  });

  testWidgets('tapping undo reverts the last add', (tester) async {
    await _pumpCard(tester);

    await tester.tap(find.text('+500 ml'));
    await tester.pumpAndSettle();
    expect(find.text('500 / 2000ml'), findsOneWidget);

    await tester.tap(find.text('Undo +500 ml'));
    await tester.pumpAndSettle();

    expect(find.text('0 / 2000ml'), findsOneWidget);
    expect(find.textContaining('Undo'), findsNothing);
  });
}
