import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(FirebaseFirestore.instance);
});

class ReservationsRepository {
  ReservationsRepository(this.db);
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('reservations');

  Stream<List<Reservation>> watchUserReservations(String userId) {
    // Avoid composite index requirement by sorting client-side
    return _col.where('userId', isEqualTo: userId).snapshots().map((s) {
      final list = s.docs.map(Reservation.fromDoc).toList();
      list.sort((a, b) => b.startAt.compareTo(a.startAt));
      return list;
    });
  }

  Future<String> createReservation({
    required String userId,
    required LotZoneOption option,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final data = Reservation(
      id: 'tmp',
      userId: userId,
      lotId: option.lotId,
      lotName: option.lotName,
      zoneId: option.zoneId,
      zoneName: option.zoneName,
      startAt: startAt,
      endAt: endAt,
      status: 'active',
    ).toMap();
    final docRef = _col.doc();
    await docRef.set(data);
    return docRef.id;
  }

  Future<void> cancelReservation(String id) async {
    await _col.doc(id).update({'status': 'canceled'});
  }
}


