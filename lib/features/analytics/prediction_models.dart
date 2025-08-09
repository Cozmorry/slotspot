import 'package:flutter/foundation.dart';

@immutable
class PredictionPoint {
  final DateTime timestamp;
  final int predictedOccupied;
  final int capacity;

  const PredictionPoint({
    required this.timestamp,
    required this.predictedOccupied,
    required this.capacity,
  });

  double get utilization => capacity == 0 ? 0 : predictedOccupied / capacity;
}

@immutable
class ZonePrediction {
  final String lotId;
  final String zoneId;
  final String zoneName;
  final int capacity;
  final List<PredictionPoint> points;

  const ZonePrediction({
    required this.lotId,
    required this.zoneId,
    required this.zoneName,
    required this.capacity,
    required this.points,
  });
}


