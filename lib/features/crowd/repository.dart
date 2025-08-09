import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';

final crowdRepositoryProvider = Provider<CrowdRepository>((ref) {
  return CrowdRepository(FirebaseFirestore.instance);
});

class CrowdRepository {
  CrowdRepository(this.db);
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> get _col => db.collection('crowdReports');

  Future<void> submitReport(CrowdReport report) async {
    final doc = _col.doc();
    await doc.set(report.toMap());
  }

  Stream<int> watchZoneEstimate(String lotId, String zoneId) {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 30));
    return _col
        .where('lotId', isEqualTo: lotId)
        .where('zoneId', isEqualTo: zoneId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .snapshots()
        .map((snap) => snap.docs.fold<int>(0, (acc, d) => acc + (d.data()['delta'] as num).toInt()));
  }
}


