import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prediction_models.dart';

/// Very simple baseline demand predictor.
/// - Uses hour-of-day and day-of-week seasonal profiles
/// - Applies exponential smoothing to a recent occupancy estimate (if provided later)
final predictionServiceProvider = Provider<DemandPredictionService>((ref) {
  return DemandPredictionService();
});

class DemandPredictionService {

  /// Returns predictions for the next 12 hours at 30-minute intervals.
  ZonePrediction predictZone({
    required String lotId,
    required String zoneId,
    required String zoneName,
    required int capacity,
    DateTime? from,
  }) {
    final DateTime start = (from ?? DateTime.now()).toLocal();

    final List<PredictionPoint> points = [];
    final Random rng = Random(zoneId.hashCode ^ start.hour ^ start.day);

    double recentUtilization = _baselineUtilization(start);
    for (int i = 0; i < 24; i++) {
      final DateTime ts = start.add(Duration(minutes: 30 * i));
      final double seasonal = _seasonalUtilization(ts);
      // Combine seasonal with a small random walk to look less flat
      recentUtilization = 0.8 * seasonal + 0.2 * (recentUtilization + (rng.nextDouble() - 0.5) * 0.1);
      final double bounded = recentUtilization.clamp(0.05, 0.98);
      final int predictedOccupied = (bounded * capacity).round();
      points.add(PredictionPoint(timestamp: ts, predictedOccupied: predictedOccupied, capacity: capacity));
    }

    return ZonePrediction(
      lotId: lotId,
      zoneId: zoneId,
      zoneName: zoneName,
      capacity: capacity,
      points: points,
    );
  }

  double _baselineUtilization(DateTime dt) {
    return _seasonalUtilization(dt);
  }

  /// Crude seasonal curve: busier weekday midday and early evening.
  double _seasonalUtilization(DateTime dt) {
    final int dow = dt.weekday; // 1 Mon .. 7 Sun
    final int hour = dt.hour;
    final bool isWeekend = dow == DateTime.saturday || dow == DateTime.sunday;

    double base = isWeekend ? 0.45 : 0.55;
    // Peak around 12-14 and 17-19
    final double midDay = _gauss(hour.toDouble(), mean: 13, sigma: 2.5) * 0.35;
    final double evening = _gauss(hour.toDouble(), mean: 18, sigma: 2.0) * 0.30;
    return (base + midDay + evening).clamp(0.05, 0.95);
  }

  double _gauss(double x, {required double mean, required double sigma}) {
    final double z = (x - mean) / sigma;
    return exp(-0.5 * z * z);
  }
}


