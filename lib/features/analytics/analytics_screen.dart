import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prediction_service.dart';

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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Demand prediction (next 12h)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: prediction.points.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = prediction.points[index];
                final time = TimeOfDay.fromDateTime(p.timestamp).format(context);
                final percent = (p.utilization * 100).toStringAsFixed(0);
                return ListTile(
                  title: Text('$time  —  ${p.predictedOccupied}/${p.capacity} occupied'),
                  subtitle: LinearProgressIndicator(value: p.utilization),
                  trailing: Text('$percent%'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


