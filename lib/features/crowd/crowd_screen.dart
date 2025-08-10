import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/permission_service.dart';
import '../../ui/widgets.dart';
import '../auth/auth_providers.dart';
import '../reservations/models.dart';
import 'realistic_crowd_service.dart';

class CrowdScreenView extends ConsumerStatefulWidget {
  const CrowdScreenView({super.key});

  @override
  ConsumerState<CrowdScreenView> createState() => _CrowdScreenViewState();
}

class _CrowdScreenViewState extends ConsumerState<CrowdScreenView> {
  LotZoneOption _option = defaultSaritOptions.first;
  RealisticAvailability? _currentAvailability;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<Position?> _getLocation() async {
    final ok = await ref.read(permissionServiceProvider).ensureLocationPermission();
    if (!ok) return null;
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  Future<void> _loadAvailability() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final availabilityNotifier = ref.read(availabilityStateProvider.notifier);
      final availability = await availabilityNotifier.getAvailability(
        lotId: _option.lotId,
        zoneId: _option.zoneId,
        capacity: _option.capacity,
      );
      
      if (mounted) {
        setState(() {
          _currentAvailability = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAvailability() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final availabilityNotifier = ref.read(availabilityStateProvider.notifier);
      await availabilityNotifier.refreshAvailability(
        lotId: _option.lotId,
        zoneId: _option.zoneId,
        capacity: _option.capacity,
      );
      
      // Get the updated availability from state
      final availability = await availabilityNotifier.getAvailability(
        lotId: _option.lotId,
        zoneId: _option.zoneId,
        capacity: _option.capacity,
      );
      
      if (mounted) {
        setState(() {
          _currentAvailability = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    }

  Widget _buildAvailabilityCard() {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Loading availability...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_currentAvailability == null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unable to load availability',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Showing basic information. Try refreshing.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AvailabilityChip(
                      label: 'Available',
                      value: '${_option.capacity}/${_option.capacity}',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AvailabilityChip(
                      label: 'Utilization',
                      value: '0%',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final availability = _currentAvailability!;
    final utilizationPercent = (availability.utilizationRate * 100).toStringAsFixed(0);
    final confidencePercent = (availability.confidence * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Availability',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: _refreshAvailability,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh availability',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AvailabilityChip(
                    label: 'Available',
                    value: '${availability.estimatedAvailable}/${availability.totalSlots}',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AvailabilityChip(
                    label: 'Utilization',
                    value: '$utilizationPercent%',
                    color: availability.utilizationRate > 0.8 ? Colors.orange : Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _AvailabilityChip(
                    label: 'Confidence',
                    value: '$confidencePercent%',
                    color: availability.confidence > 0.7 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
                         if (availability.crowdReportedOccupied > 0 || availability.crowdReportedFree > 0) ...[
               const SizedBox(height: 12),
               Text(
                 'Net Crowd Reports',
                 style: Theme.of(context).textTheme.titleSmall,
               ),
               const SizedBox(height: 8),
               Row(
                 children: [
                   if (availability.crowdReportedFree > 0)
                     Chip(
                       avatar: const Icon(Icons.add, size: 16),
                       label: Text('${availability.crowdReportedFree} net free'),
                       backgroundColor: Colors.green.withOpacity(0.2),
                     ),
                   if (availability.crowdReportedOccupied > 0) ...[
                     const SizedBox(width: 8),
                     Chip(
                       avatar: const Icon(Icons.remove, size: 16),
                       label: Text('${availability.crowdReportedOccupied} net occupied'),
                       backgroundColor: Colors.red.withOpacity(0.2),
                     ),
                   ],
                 ],
               ),
             ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final realisticService = ref.watch(realisticCrowdServiceProvider);

    return RefreshIndicator(
      onRefresh: _refreshAvailability,
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
                             onChanged: (v) {
                 setState(() => _option = v ?? _option);
                 // Clear cache and load fresh data for new selection
                 ref.read(availabilityStateProvider.notifier).clearCache();
                 _loadAvailability();
               },
              decoration: const InputDecoration(labelText: 'Lot / Zone'),
            ),
            const SizedBox(height: 12),
            _buildAvailabilityCard(),
            const SizedBox(height: 24),
            Text(
              'Report Changes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Help others by reporting when you see a slot become available or occupied.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 12, children: [
              FilledButton.icon(
                onPressed: user == null
                    ? null
                    : () async {
                        final pos = await _getLocation();
                        final success = await realisticService.submitRealisticReport(
                          userId: user.uid,
                          lotId: _option.lotId,
                          zoneId: _option.zoneId,
                          capacity: _option.capacity,
                          delta: 1, // +1 for free slot
                          lat: pos?.latitude,
                          lng: pos?.longitude,
                        );
                        
                                                 if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text(success 
                                 ? 'Free slot reported successfully!' 
                                 : 'Report rejected - no changes needed'),
                               backgroundColor: success ? Colors.green : Colors.orange,
                             ),
                           );
                           if (success) {
                             _refreshAvailability(); // Refresh after successful report
                           }
                         }
                      },
                icon: const Icon(Icons.add),
                label: const Text('Report free slot'),
              ),
              OutlinedButton.icon(
                onPressed: user == null
                    ? null
                    : () async {
                        final pos = await _getLocation();
                        final success = await realisticService.submitRealisticReport(
                          userId: user.uid,
                          lotId: _option.lotId,
                          zoneId: _option.zoneId,
                          capacity: _option.capacity,
                          delta: -1, // -1 for occupied slot
                          lat: pos?.latitude,
                          lng: pos?.longitude,
                        );
                        
                                                 if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(
                               content: Text(success 
                                 ? 'Occupied slot reported successfully!' 
                                 : 'Report rejected - no changes needed'),
                               backgroundColor: success ? Colors.green : Colors.orange,
                             ),
                           );
                           if (success) {
                             _refreshAvailability(); // Refresh after successful report
                           }
                         }
                      },
                icon: const Icon(Icons.remove),
                label: const Text('Report occupied'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


