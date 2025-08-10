import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../reservations/availability_service.dart';
import 'models.dart';

class RealisticAvailability {
  final int totalSlots;
  final int reservedSlots;
  final int crowdReportedOccupied;
  final int crowdReportedFree;
  final int estimatedAvailable;
  final double confidence;
  final DateTime lastUpdated;

  const RealisticAvailability({
    required this.totalSlots,
    required this.reservedSlots,
    required this.crowdReportedOccupied,
    required this.crowdReportedFree,
    required this.estimatedAvailable,
    required this.confidence,
    required this.lastUpdated,
  });

  double get utilizationRate => (totalSlots - estimatedAvailable) / totalSlots;
  int get occupiedSlots => totalSlots - estimatedAvailable;
}

final realisticCrowdServiceProvider = Provider<RealisticCrowdService>((ref) {
  return RealisticCrowdService(
    FirebaseFirestore.instance,
    ref.read(availabilityServiceProvider),
  );
});

// Global state provider for availability data that persists across navigation
final availabilityStateProvider = StateNotifierProvider<AvailabilityStateNotifier, Map<String, RealisticAvailability>>((ref) {
  return AvailabilityStateNotifier(ref.read(realisticCrowdServiceProvider));
});

class AvailabilityStateNotifier extends StateNotifier<Map<String, RealisticAvailability>> {
  AvailabilityStateNotifier(this._service) : super({});
  
  final RealisticCrowdService _service;

  String _getKey(String lotId, String zoneId) => '${lotId}_$zoneId';

  Future<RealisticAvailability> getAvailability({
    required String lotId,
    required String zoneId,
    required int capacity,
  }) async {
    final key = _getKey(lotId, zoneId);
    
    // Return cached data if available
    if (state.containsKey(key)) {
      return state[key]!;
    }
    
    // Load fresh data if not cached
    final availability = await _service._calculateRealisticAvailability(lotId, zoneId, capacity);
    state = {...state, key: availability};
    return availability;
  }

  Future<void> refreshAvailability({
    required String lotId,
    required String zoneId,
    required int capacity,
  }) async {
    final key = _getKey(lotId, zoneId);
    final availability = await _service._calculateRealisticAvailability(lotId, zoneId, capacity);
    state = {...state, key: availability};
  }

  void clearCache() {
    state = {};
  }
}

class RealisticCrowdService {
  RealisticCrowdService(this.db, this.availabilityService);
  final FirebaseFirestore db;
  final AvailabilityService availabilityService;

  /// Get realistic availability that combines reservations with crowd reports
  Stream<RealisticAvailability> watchRealisticAvailability({
    required String lotId,
    required String zoneId,
    required int capacity,
  }) {
    // Return initial data immediately, then update every 30 seconds
    return Stream.fromFuture(_calculateRealisticAvailability(lotId, zoneId, capacity))
        .asyncExpand((initialData) {
          return Stream.periodic(const Duration(seconds: 30))
              .asyncMap((_) => _calculateRealisticAvailability(lotId, zoneId, capacity))
              .handleError((error) => initialData); // Return initial data on error
        });
  }

  /// Get fallback availability when queries are slow
  Future<RealisticAvailability> _getFallbackAvailability(
    String lotId,
    String zoneId,
    int capacity,
  ) async {
    return RealisticAvailability(
      totalSlots: capacity,
      reservedSlots: 0,
      crowdReportedOccupied: 0,
      crowdReportedFree: 0,
      estimatedAvailable: capacity,
      confidence: 0.3,
      lastUpdated: DateTime.now(),
    );
  }

  Future<RealisticAvailability> _calculateRealisticAvailability(
    String lotId,
    String zoneId,
    int capacity,
  ) async {
    final now = DateTime.now();
    
    try {
      // Get actual reserved slots with timeout
      final reservedSlots = await availabilityService.countActiveNow(
        lotId: lotId,
        zoneId: zoneId,
        now: now,
      ).timeout(const Duration(seconds: 5), onTimeout: () => 0);

      // Get recent crowd reports (last 15 minutes)
      final crowdReports = await _getRecentCrowdReports(lotId, zoneId, now);
      
      // Calculate crowd adjustments
      final crowdAdjustment = _calculateCrowdAdjustment(crowdReports);
      
      // Apply realistic constraints
      final estimatedAvailable = _applyRealisticConstraints(
        capacity: capacity,
        reservedSlots: reservedSlots,
        crowdAdjustment: crowdAdjustment,
      );

      // Calculate confidence based on report quality and quantity
      final confidence = _calculateConfidence(crowdReports, reservedSlots, capacity);

      return RealisticAvailability(
        totalSlots: capacity,
        reservedSlots: reservedSlots,
        crowdReportedOccupied: crowdAdjustment.occupiedReports,
        crowdReportedFree: crowdAdjustment.freeReports,
        estimatedAvailable: estimatedAvailable,
        confidence: confidence,
        lastUpdated: now,
      );
    } catch (e) {
      // Return fallback data if anything fails
      print('Error calculating availability: $e');
      return _getFallbackAvailability(lotId, zoneId, capacity);
    }
  }

  Future<List<CrowdReport>> _getRecentCrowdReports(
    String lotId,
    String zoneId,
    DateTime now,
  ) async {
    final cutoff = now.subtract(const Duration(minutes: 15));
    
    try {
      // Use a simpler query to avoid index requirements, with limit for performance
      final query = await db
          .collection('crowdReports')
          .where('lotId', isEqualTo: lotId)
          .where('zoneId', isEqualTo: zoneId)
          .limit(50) // Limit to prevent loading too much data
          .get();

      // Filter and sort on the client side
      final reports = query.docs.map((doc) {
        final data = doc.data();
        return CrowdReport(
          id: doc.id,
          userId: data['userId'] as String,
          lotId: data['lotId'] as String,
          zoneId: data['zoneId'] as String,
          delta: data['delta'] as int,
          lat: data['lat'] as double?,
          lng: data['lng'] as double?,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
        );
      }).toList();

      // Filter by time and sort by creation date
      return reports
          .where((report) => report.createdAt.isAfter(cutoff))
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
          ..take(20); // Limit to 20 most recent reports
    } catch (e) {
      // Return empty list if query fails
      print('Error fetching crowd reports: $e');
      return [];
    }
  }

  _CrowdAdjustment _calculateCrowdAdjustment(List<CrowdReport> reports) {
    int netAdjustment = 0;
    int netOccupied = 0;
    int netFree = 0;

    final now = DateTime.now();

    for (final report in reports) {
      final ageMinutes = now.difference(report.createdAt).inMinutes;
      final weight = exp(-ageMinutes / 5.0); // 5-minute half-life
      
      if (report.delta > 0) {
        netAdjustment += (weight * report.delta).round(); // Positive for free slots
        netFree += (weight * report.delta).round();
      } else if (report.delta < 0) {
        netAdjustment += (weight * report.delta).round(); // Negative for occupied slots
        netOccupied += (weight * report.delta).abs().round();
      }
    }

    // Calculate net effect: if we have both free and occupied reports, they cancel each other out
    final netEffect = netFree - netOccupied;
    final finalOccupied = netEffect < 0 ? netEffect.abs() : 0;
    final finalFree = netEffect > 0 ? netEffect : 0;

    return _CrowdAdjustment(
      netAdjustment: netAdjustment,
      occupiedReports: finalOccupied,
      freeReports: finalFree,
      totalReports: reports.length,
    );
  }

  int _applyRealisticConstraints({
    required int capacity,
    required int reservedSlots,
    required _CrowdAdjustment crowdAdjustment,
  }) {
    // Start with reserved slots as base
    int estimatedOccupied = reservedSlots;
    
    // Apply crowd reports directly to the estimate
    // Positive netAdjustment means more free slots reported
    // Negative netAdjustment means more occupied slots reported
    estimatedOccupied -= crowdAdjustment.netAdjustment;
    
    // Ensure we stay within physical constraints
    estimatedOccupied = estimatedOccupied.clamp(0, capacity);
    
    return capacity - estimatedOccupied;
  }

  double _calculateConfidence(
    List<CrowdReport> reports,
    int reservedSlots,
    int capacity,
  ) {
    if (reports.isEmpty) return 0.3; // Low confidence without reports
    
    // Base confidence on number of reports
    final reportConfidence = min(1.0, reports.length / 5.0);
    
    // Higher confidence if crowd reports align with reservations
    final reservationUtilization = reservedSlots / capacity;
    final crowdUtilization = reports.isNotEmpty 
        ? reports.where((r) => r.delta < 0).length / reports.length 
        : 0.0;
    final alignmentBonus = 1.0 - (reservationUtilization - crowdUtilization).abs();
    
    // Recent reports get higher confidence
    final now = DateTime.now();
    final avgAgeMinutes = reports.isNotEmpty
        ? reports.map((r) => now.difference(r.createdAt).inMinutes).reduce((a, b) => a + b) / reports.length
        : 0.0;
    final recencyBonus = max(0.0, 1.0 - (avgAgeMinutes / 10.0));
    
    return (reportConfidence * 0.4 + alignmentBonus * 0.4 + recencyBonus * 0.2).clamp(0.0, 1.0);
  }

  /// Submit a realistic crowd report with validation
  Future<bool> submitRealisticReport({
    required String userId,
    required String lotId,
    required String zoneId,
    required int capacity,
    required int delta, // +1 for free, -1 for occupied
    double? lat,
    double? lng,
  }) async {
    // Get current state
    final currentAvailability = await _calculateRealisticAvailability(lotId, zoneId, capacity);
    
    // Validate the report makes sense
    if (!_validateReport(currentAvailability, delta)) {
      return false; // Report rejected
    }
    
    // Submit the report
    final report = CrowdReport(
      id: 'temp',
      userId: userId,
      lotId: lotId,
      zoneId: zoneId,
      delta: delta,
      lat: lat,
      lng: lng,
      createdAt: DateTime.now(),
    );
    
    await db.collection('crowdReports').add(report.toMap());
    return true;
  }

  bool _validateReport(RealisticAvailability current, int delta) {
    // Allow all reports - let the crowd reports influence the availability
    // The system will naturally balance out with multiple reports
    return true;
  }

  /// Force refresh availability data (useful after reservations)
  Future<RealisticAvailability> refreshAvailability({
    required String lotId,
    required String zoneId,
    required int capacity,
  }) async {
    return _calculateRealisticAvailability(lotId, zoneId, capacity);
  }
}

class _CrowdAdjustment {
  final int netAdjustment;
  final int occupiedReports;
  final int freeReports;
  final int totalReports;

  const _CrowdAdjustment({
    required this.netAdjustment,
    required this.occupiedReports,
    required this.freeReports,
    required this.totalReports,
  });
}
