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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.event_available_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reserve Parking',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  'Book your parking slot in advance',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Reservation Form Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          Theme.of(context).colorScheme.surfaceContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.settings_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Reservation Details',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Zone Selection
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: DropdownButtonFormField<LotZoneOption>(
                            value: _option,
                            items: [
                              for (final o in defaultSaritOptions)
                                DropdownMenuItem(
                                  value: o,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 20,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${o.lotName} — ${o.zoneName}'),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => _option = v ?? _option),
                            decoration: InputDecoration(
                              labelText: 'Select Parking Zone',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              prefixIcon: Icon(
                                Icons.map_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Time Selection
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickDateTime(context, true),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.schedule_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  label: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Time',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        TimeOfDay.fromDateTime(_start).format(context),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                child: OutlinedButton.icon(
                                  onPressed: () => _pickDateTime(context, false),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.timelapse_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  label: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Time',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        TimeOfDay.fromDateTime(_end).format(context),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Reserve Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FilledButton.icon(
                            onPressed: userId == null ? null : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final hasSpace = await availability.hasCapacity(option: _option, startAt: _start, endAt: _end);
                              if (!hasSpace) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: const Text('No capacity available for this time window.'),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                                return;
                              }
                              await repo.createReservation(userId: userId, option: _option, startAt: _start, endAt: _end);
                              setState(() {}); // trigger UI to refresh list below
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Reservation created successfully!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.event_available_rounded, size: 24),
                            label: const Text(
                              'Reserve Parking Slot',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Reservations List
                  userId == null
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.login_rounded,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Sign in to view reservations',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _ReservationsAndQr(userId: userId),
                ],
              ),
            ),
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
            // Reservations Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Your Reservations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Modern Reservations List
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: top.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
                itemBuilder: (context, index) {
                  final r = top[index];
                  final isExpired = now.isAfter(r.endAt);
                  final isInactive = isExpired || r.status != 'active';
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(20) : Radius.zero,
                        bottom: index == top.length - 1 ? const Radius.circular(20) : Radius.zero,
                      ),
                    ),
                    child: ListTile(
                      enabled: !isInactive,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isInactive 
                            ? Theme.of(context).colorScheme.outline.withOpacity(0.1)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isExpired ? Icons.history_rounded : Icons.local_parking_rounded,
                          color: isInactive 
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${r.lotName} — ${r.zoneName}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isInactive 
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : null,
                        ),
                      ),
                      subtitle: Text(
                        '${TimeOfDay.fromDateTime(r.startAt).format(context)} → ${TimeOfDay.fromDateTime(r.endAt).format(context)}',
                        style: TextStyle(
                          color: isInactive 
                            ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: isInactive ? null : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ReservationDetailScreen(reservationId: r.id)),
                        );
                      },
                      trailing: isExpired
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'expired',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : (r.status == 'active'
                            ? TextButton(
                                onPressed: () => repo.cancelReservation(r.id),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Cancel'),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  r.status,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            _ModernQrCard(reservation: active),
          ],
        );
      },
    );
  }
}

class _ModernQrCard extends StatelessWidget {
  const _ModernQrCard({required this.reservation});
  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = now.isAfter(reservation.endAt);
    final isCancelled = reservation.status != 'active';
    final isInactive = isExpired || isCancelled;
    final stateLabel = isExpired ? 'Expired' : (isCancelled ? 'Cancelled' : 'Active');
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isInactive 
                      ? Colors.orange.withOpacity(0.1)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.qr_code_rounded,
                    color: isInactive 
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your QR Code',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isInactive 
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stateLabel,
                              style: TextStyle(
                                color: isInactive ? Colors.orange : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Reservation Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${reservation.lotName} — ${reservation.zoneName}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${TimeOfDay.fromDateTime(reservation.startAt).format(context)} → ${TimeOfDay.fromDateTime(reservation.endAt).format(context)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // QR Code
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: isInactive ? 0.4 : 1.0,
                  child: QrImageView(
                    data: reservation.id,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: OutlinedButton.icon(
                      onPressed: isInactive ? null : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ReservationDetailScreen(reservationId: reservation.id)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.fullscreen_rounded),
                      label: const Text('Full Screen'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isInactive 
                          ? [Colors.grey, Colors.grey.shade600]
                          : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FilledButton.icon(
                      onPressed: isInactive ? null : () => Share.share('SlotSpot reservation: ${reservation.id}'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


