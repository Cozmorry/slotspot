import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CrowdEstimate {
  final double freeScore; // positive means more free (will be rounded when presented)
  final int reportsCount;
  final double confidence; // 0..1
  final DateTime updatedAt;

  const CrowdEstimate({
    required this.freeScore,
    required this.reportsCount,
    required this.confidence,
    required this.updatedAt,
  });
}

final crowdEstimatorProvider = Provider<CrowdEstimator>((ref) {
  return CrowdEstimator(FirebaseFirestore.instance);
});

class CrowdEstimator {
  CrowdEstimator(this.db);
  final FirebaseFirestore db;

  /// Exponentially decayed sum of +/- 1 crowd reports within the last 30 minutes
  /// tauMinutes controls decay aggressiveness (smaller = faster decay)
  Stream<CrowdEstimate> watchZoneFreeScore({
    required String lotId,
    required String zoneId,
    int tauMinutes = 10,
  }) {
    // Important: don't filter by createdAt in the query because new docs use
    // server timestamps and may appear with createdAt=null initially, so they
    // would be excluded. Filter by cutoff on the client side.
    final query = db
        .collection('crowdReports')
        .where('lotId', isEqualTo: lotId)
        .where('zoneId', isEqualTo: zoneId);

    final tau = Duration(minutes: tauMinutes);
    return query.snapshots().map((snap) {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(minutes: 30));
      double score = 0;
      int count = 0;
      for (final d in snap.docs) {
        final data = d.data();
        final ts = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
        if (ts.isBefore(cutoff)) continue;
        final deltaMinutes = now.difference(ts).inSeconds / 60.0;
        final weight = exp(-max(0, deltaMinutes) / tau.inMinutes);
        final delta = (data['delta'] as num).toDouble();
        score += delta * weight;
        count += 1;
      }
      // Confidence grows with number and recency of reports
      final confidence = (1 - exp(-count / 5)) * (score.abs() > 0 ? min(1, score.abs() / 5) : 0.5);
      return CrowdEstimate(
        freeScore: score,
        reportsCount: count,
        confidence: confidence.clamp(0, 1),
        updatedAt: DateTime.now(),
      );
    });
  }
}


