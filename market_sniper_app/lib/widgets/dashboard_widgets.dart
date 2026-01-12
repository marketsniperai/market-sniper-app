import 'package:flutter/material.dart';
import '../models/dashboard_payload.dart';

class UnknownWidgetCard extends StatelessWidget {
  final DashboardWidget widget;

  const UnknownWidgetCard({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("UNKNOWN WIDGET: ${widget.type}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.data.toString(),
                style: const TextStyle(fontFamily: 'Monospace', fontSize: 10)),
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
    Color color = Colors.grey;
    if (sentiment == 'BULLISH') color = Colors.green;
    if (sentiment == 'BEARISH') color = Colors.red;

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(widget.title, style: const TextStyle(color: Colors.white54)),
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
      color: Colors.blueGrey[900],
      child: ListTile(
        leading: const Icon(Icons.security, color: Colors.cyanAccent),
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
