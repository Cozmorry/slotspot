import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prediction_service.dart';
import 'prediction_models.dart';

class AnalyticsScreenView extends ConsumerWidget {
  const AnalyticsScreenView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictor = ref.watch(predictionServiceProvider);
    final prediction = predictor.predictZone(
      lotId: 'sarit',
      zoneId: 'A',
      zoneName: 'Zone A',
      capacity: 120,
    );

    return RefreshIndicator(
      onRefresh: () async {},
      child: FutureBuilder<ZonePrediction>(
        future: Future.value(prediction),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Failed to load predictions', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }
          
          final prediction = snapshot.data!;
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Demand prediction (next 12h)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...List.generate(prediction.points.length, (index) {
                final p = prediction.points[index];
                final time = TimeOfDay.fromDateTime(p.timestamp).format(context);
                final percent = (p.utilization * 100).toStringAsFixed(0);
                return Column(
                  children: [
                    ListTile(
                      title: Text('$time  —  ${p.predictedOccupied}/${p.capacity} occupied'),
                      subtitle: LinearProgressIndicator(value: p.utilization),
                      trailing: Text('$percent%'),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}


