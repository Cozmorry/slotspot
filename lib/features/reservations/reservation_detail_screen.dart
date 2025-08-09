import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ReservationDetailScreen extends StatelessWidget {
  const ReservationDetailScreen({super.key, required this.reservationId});
  final String reservationId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Show this code at the gate', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16)],
                ),
                child: QrImageView(
                  data: reservationId,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(reservationId, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Share.share('SlotSpot reservation: $reservationId');
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


