import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../auth/auth_providers.dart';
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

  Future<void> _showQrBottomSheet(String reservationId) async {
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reservation QR', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16)],
              ),
              child: QrImageView(data: reservationId, version: QrVersions.auto, size: 220, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            SelectableText(reservationId, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ReservationDetailScreen(reservationId: reservationId),
                ));
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open full screen'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateChangesProvider).asData?.value;
    final repo = ref.watch(reservationsRepositoryProvider);
    final availability = ref.watch(availabilityServiceProvider);
    final userId = authUser?.uid;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reserve a slot', style: Theme.of(context).textTheme.titleLarge),
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
                    final id = await repo.createReservation(userId: userId, option: _option, startAt: _start, endAt: _end);
                    setState(() {}); // trigger UI to refresh list below
                    messenger.showSnackBar(const SnackBar(content: Text('Reservation created')));
                    await _showQrBottomSheet(id);
                  },
            icon: const Icon(Icons.event_available),
            label: const Text('Reserve'),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: userId == null
                ? const Center(child: Text('Sign in to view reservations'))
                : _UserReservationsList(userId: userId),
          ),
        ],
      ),
    );
  }
}

class _UserReservationsList extends ConsumerWidget {
  const _UserReservationsList({required this.userId});
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

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final r = items[index];
            final now = DateTime.now();
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
        );
      },
    );
  }
}


