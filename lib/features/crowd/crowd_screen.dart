import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

import '../../services/permission_service.dart';
import '../../ui/widgets.dart';
import 'estimator.dart';
import '../auth/auth_providers.dart';
import '../reservations/models.dart';
import '../reservations/availability_service.dart';
import 'models.dart';
import 'repository.dart';

class CrowdScreenView extends ConsumerStatefulWidget {
  const CrowdScreenView({super.key});

  @override
  ConsumerState<CrowdScreenView> createState() => _CrowdScreenViewState();
}

class _CrowdScreenViewState extends ConsumerState<CrowdScreenView> {
  LotZoneOption _option = defaultSaritOptions.first;

  Future<Position?> _getLocation() async {
    final ok = await ref.read(permissionServiceProvider).ensureLocationPermission();
    if (!ok) return null;
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final repo = ref.watch(crowdRepositoryProvider);
    final estimateStream = ref.watch(crowdEstimatorProvider).watchZoneFreeScore(lotId: _option.lotId, zoneId: _option.zoneId);
    final availabilitySvc = ref.watch(availabilityServiceProvider);

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SectionTitle('Report slot availability'),
          const SizedBox(height: 12),
          DropdownButtonFormField<LotZoneOption>(
            value: _option,
            items: [for (final o in defaultSaritOptions) DropdownMenuItem(value: o, child: Text('${o.lotName} — ${o.zoneName}'))],
            onChanged: (v) => setState(() => _option = v ?? _option),
            decoration: const InputDecoration(labelText: 'Lot / Zone'),
          ),
          const SizedBox(height: 12),
          StreamBuilder<CrowdEstimate>(
            stream: estimateStream,
            builder: (context, snapshot) {
              final est = snapshot.data;
              return FutureBuilder<int>(
                future: availabilitySvc.countActiveNow(lotId: _option.lotId, zoneId: _option.zoneId),
                builder: (context, activeSnap) {
                  final activeNow = activeSnap.data ?? 0;
                  // Convert score to integer adjustment and combine with active reservations
                  final rounded = (est?.freeScore ?? 0).round();
                  final usedApprox = (activeNow - math.min(0, rounded)).clamp(0, _option.capacity);
                  final available = (_option.capacity - usedApprox).clamp(0, _option.capacity);
                  final availabilityText = 'Slots: $available/${_option.capacity}';
                  final conf = ((est?.confidence ?? 0) * 100).toStringAsFixed(0);
                  return Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Chip(label: Text(availabilityText)),
                      Chip(label: Text('Availability: $conf%')),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(spacing: 12, children: [
            FilledButton.icon(
              onPressed: user == null
                  ? null
                  : () async {
                      final pos = await _getLocation();
                      await repo.submitReport(CrowdReport(
                        id: 'tmp',
                        userId: user.uid,
                        lotId: _option.lotId,
                        zoneId: _option.zoneId,
                        delta: 1,
                        lat: pos?.latitude,
                        lng: pos?.longitude,
                        createdAt: DateTime.now(),
                      ));
                      if (mounted) setState(() {});
                    },
              icon: const Icon(Icons.add),
              label: const Text('Report free slot (+1)'),
            ),
            OutlinedButton.icon(
              onPressed: user == null
                  ? null
                  : () async {
                      final pos = await _getLocation();
                      await repo.submitReport(CrowdReport(
                        id: 'tmp',
                        userId: user.uid,
                        lotId: _option.lotId,
                        zoneId: _option.zoneId,
                        delta: -1,
                        lat: pos?.latitude,
                        lng: pos?.longitude,
                        createdAt: DateTime.now(),
                      ));
                      if (mounted) setState(() {});
                    },
              icon: const Icon(Icons.remove),
              label: const Text('Report occupied (-1)'),
            ),
          ]),
          ],
        ),
      ),
    );
  }
}


