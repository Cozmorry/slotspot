import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

final availabilityServiceProvider = Provider<AvailabilityService>((ref) {
  return AvailabilityService(FirebaseFirestore.instance);
});

class AvailabilityService {
  AvailabilityService(this.db);
  final FirebaseFirestore db;

  /// Very simple availability: count active reservations overlapping the window
  /// and compare against capacity for the zone.
  Future<int> countActiveReservations({
    required String lotId,
    required String zoneId,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    // Use only equality filters to avoid composite index requirement; filter overlaps client-side
    final qs = await db
        .collection('reservations')
        .where('lotId', isEqualTo: lotId)
        .where('zoneId', isEqualTo: zoneId)
        .where('status', isEqualTo: 'active')
        .get();
    int overlapping = 0;
    for (final d in qs.docs) {
      final data = d.data();
      final otherStart = (data['startAt'] as Timestamp).toDate();
      final otherEnd = (data['endAt'] as Timestamp).toDate();
      final overlaps = otherEnd.isAfter(startAt) && otherStart.isBefore(endAt);
      if (overlaps) overlapping++;
    }
    return overlapping;
  }

  Future<bool> hasCapacity({required LotZoneOption option, required DateTime startAt, required DateTime endAt}) async {
    final used = await countActiveReservations(
      lotId: option.lotId,
      zoneId: option.zoneId,
      startAt: startAt,
      endAt: endAt,
    );
    return used < option.capacity;
  }
}


