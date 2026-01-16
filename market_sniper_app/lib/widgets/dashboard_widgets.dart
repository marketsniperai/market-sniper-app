import 'package:flutter/material.dart';
import '../models/dashboard_payload.dart';
import '../theme/app_colors.dart';

class UnknownWidgetCard extends StatelessWidget {
  final DashboardWidget widget;

  const UnknownWidgetCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.stateLocked.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("UNKNOWN WIDGET: ${widget.type}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.stateLocked)),
            const SizedBox(height: 8),
            Text(widget.data.toString(),
                style: const TextStyle(fontFamily: 'Monospace', fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class DeltaCard extends StatelessWidget {
  final DashboardWidget widget;

  const DeltaCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    final value = widget.data['value'] ?? '--';
    final sentiment = widget.data['sentiment'] ?? 'NEUTRAL';
    Color color = AppColors.textSecondary;
    if (sentiment == 'BULLISH') color = AppColors.marketBull;
    if (sentiment == 'BEARISH') color = AppColors.marketBear;

    return Card(
      color: AppColors.surface1,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(widget.title, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 48, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(sentiment, style: TextStyle(color: color)),
            )
          ],
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final DashboardWidget widget;

  const StatusCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] ?? 'UNKNOWN';
    final runId = widget.data['run_id'] ?? 'N/A';
    
    return Card(
      color: AppColors.surface1,
      child: ListTile(
        leading: const Icon(Icons.security, color: AppColors.accentCyan),
        title: Text(widget.title),
        subtitle: Text("$status (Run: $runId)"),
      ),
    );
  }
}

Widget renderWidget(DashboardWidget w) {
  switch (w.type) {
    case 'CARD_DELTA':
      return DeltaCard(widget: w);
    case 'CARD_STATUS':
      return StatusCard(widget: w);
    default:
      return UnknownWidgetCard(widget: w);
  }
}
