import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/weight_entry.dart';

class WeightEntryModel {
  const WeightEntryModel._();

  static WeightEntry fromMap(String id, Map<String, dynamic> map) {
    return WeightEntry(
      id: id,
      userId: map['userId'] as String? ?? '',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0,
      loggedDate: map['loggedDate'] as String? ?? '',
      note: map['note'] as String?,
    );
  }

  static WeightEntry fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return fromMap(snapshot.id, snapshot.data()!);
  }
}
