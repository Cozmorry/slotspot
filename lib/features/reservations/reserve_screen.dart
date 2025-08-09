import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../auth/auth_providers.dart';
import '../../ui/widgets.dart';
import 'models.dart';
import 'repository.dart';
import 'availability_service.dart';
import 'reservation_detail_screen.dart';

class ReserveView extends ConsumerStatefulWidget {
  const ReserveView({super.key});

  @override
  ConsumerState<ReserveView> createState() => _ReserveViewState();
}

class _ReserveViewState extends ConsumerState<ReserveView> {
  LotZoneOption _option = defaultSaritOptions.first;
  DateTime _start = DateTime.now().add(const Duration(minutes: 10));
  DateTime _end = DateTime.now().add(const Duration(hours: 2));

  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (pickedDate == null) return;
    if (!context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _start : _end),
    );
    if (pickedTime == null) return;
    if (!context.mounted) return;
    final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    setState(() {
      if (isStart) {
        _start = dt;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = dt;
        if (_end.isBefore(_start)) _start = _end.subtract(const Duration(hours: 1));
      }
    });
  }

  // QR is rendered inline below the list via _QrCard

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateChangesProvider).asData?.value;
    final repo = ref.watch(reservationsRepositoryProvider);
    final availability = ref.watch(availabilityServiceProvider);
    final userId = authUser?.uid;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SectionTitle('Reserve a slot'),
          const SizedBox(height: 12),
          DropdownButtonFormField<LotZoneOption>(
            value: _option,
            items: [
              for (final o in defaultSaritOptions)
                DropdownMenuItem(value: o, child: Text('${o.lotName} — ${o.zoneName}')),
            ],
            onChanged: (v) => setState(() => _option = v ?? _option),
            decoration: const InputDecoration(labelText: 'Lot / Zone'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDateTime(context, true),
                  icon: const Icon(Icons.schedule),
                  label: Text('Start: ${TimeOfDay.fromDateTime(_start).format(context)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDateTime(context, false),
                  icon: const Icon(Icons.timelapse),
                  label: Text('End: ${TimeOfDay.fromDateTime(_end).format(context)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: userId == null
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final hasSpace = await availability.hasCapacity(option: _option, startAt: _start, endAt: _end);
                    if (!hasSpace) {
                      messenger.showSnackBar(const SnackBar(content: Text('No capacity available for this time window.')));
                      return;
                    }
                   await repo.createReservation(userId: userId, option: _option, startAt: _start, endAt: _end);
                   setState(() {}); // trigger UI to refresh list below
                    messenger.showSnackBar(const SnackBar(content: Text('Reservation created')));
                  },
            icon: const Icon(Icons.event_available),
            label: const Text('Reserve'),
          ),
          const SizedBox(height: 24),
          userId == null
              ? const EmptyState(icon: Icons.login, title: 'Sign in to view reservations')
              : _ReservationsAndQr(userId: userId),
        ],
      ),
    ),
    );
  }
}

class _ReservationsAndQr extends ConsumerWidget {
  const _ReservationsAndQr({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(reservationsRepositoryProvider);
    return StreamBuilder<List<Reservation>>(
      stream: repo.watchUserReservations(userId),
      builder: (context, snapshot) {
        final items = List<Reservation>.from(snapshot.data ?? const <Reservation>[]);
        if (items.isEmpty) return const Center(child: Text('No reservations yet'));

        // Sort: active (not expired) first, then by start time desc
        final now = DateTime.now();
        items.sort((a, b) {
          final aActive = a.status == 'active' && now.isBefore(a.endAt);
          final bActive = b.status == 'active' && now.isBefore(b.endAt);
          if (aActive != bActive) return bActive ? 1 : -1; // true first
          return b.startAt.compareTo(a.startAt);
        });
        final top = items.take(3).toList();
        final active = items.firstWhere(
          (r) => r.status == 'active' && now.isBefore(r.endAt),
          orElse: () => top.isNotEmpty ? top.first : items.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: top.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final r = top[index];
                final isExpired = now.isAfter(r.endAt);
                final isInactive = isExpired || r.status != 'active';
                return ListTile(
                  enabled: !isInactive,
                  title: Text('${r.lotName} — ${r.zoneName}'),
                  subtitle: Text('${r.startAt} → ${r.endAt}'),
                  onTap: isInactive
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ReservationDetailScreen(reservationId: r.id)),
                          );
                        },
                  trailing: isExpired
                      ? Text('expired', style: Theme.of(context).textTheme.bodySmall)
                      : (r.status == 'active'
                          ? TextButton(
                              onPressed: () => repo.cancelReservation(r.id),
                              child: const Text('Cancel'),
                            )
                          : Text(r.status, style: Theme.of(context).textTheme.bodySmall)),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _QrCard(reservation: active),
          ],
        );
      },
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.reservation});
  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isExpired = now.isAfter(reservation.endAt);
    final isCancelled = reservation.status != 'active';
    final isInactive = isExpired || isCancelled;
    final stateLabel = isExpired ? 'expired' : (isCancelled ? 'cancelled' : null);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your QR code', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('${reservation.lotName} — ${reservation.zoneName}', style: Theme.of(context).textTheme.bodyMedium),
          Text('${reservation.startAt} → ${reservation.endAt}', style: Theme.of(context).textTheme.bodySmall),
          if (stateLabel != null) ...[
            const SizedBox(height: 6),
            Text(stateLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Opacity(
                opacity: isInactive ? 0.35 : 1.0,
                child: QrImageView(
                  data: reservation.id,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: isInactive
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ReservationDetailScreen(reservationId: reservation.id)),
                          ),
                  icon: const Icon(Icons.fullscreen),
                  label: const Text('Full screen'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: isInactive ? null : () => Share.share('SlotSpot reservation: ${reservation.id}'),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


