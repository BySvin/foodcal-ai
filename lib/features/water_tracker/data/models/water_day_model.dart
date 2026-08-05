import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/water_day.dart';

class WaterDayModel {
  const WaterDayModel._();

  static WaterDay fromMap(String date, Map<String, dynamic> map) {
    return WaterDay(
      date: date,
      totalMl: (map['totalMl'] as num?)?.toInt() ?? 0,
      goalMl: (map['goalMl'] as num?)?.toInt() ?? 0,
      lastAddedMl: (map['lastAddedMl'] as num?)?.toInt(),
    );
  }

  static WaterDay? fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot, String date) {
    final data = snapshot.data();
    if (data == null) return null;
    return fromMap(date, data);
  }
}
