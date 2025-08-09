import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/permission_service.dart';
import '../../ui/widgets.dart';
import '../auth/auth_providers.dart';
import '../reservations/models.dart';
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
    final estimateStream = ref.watch(crowdRepositoryProvider).watchZoneEstimate(_option.lotId, _option.zoneId);

    return Padding(
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
          StreamBuilder<int>(
            stream: estimateStream,
            builder: (context, snapshot) {
              final est = snapshot.data ?? 0;
              final text = est >= 0 ? '+$est free' : '${est.abs()} filled';
              return Chip(label: Text('Community estimate (30m): $text'));
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
                    },
              icon: const Icon(Icons.remove),
              label: const Text('Report occupied (-1)'),
            ),
          ]),
        ],
      ),
    );
  }
}


