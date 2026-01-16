import 'package:flutter/material.dart';
import '../models/system_health.dart';
import '../theme/app_colors.dart';

class SystemHealthChip extends StatefulWidget {
  final SystemHealth health;
  final bool isFounder;

  const SystemHealthChip({
    super.key,
    required this.health,
    required this.isFounder,
  });

  @override
  State<SystemHealthChip> createState() => _SystemHealthChipState();
}

class _SystemHealthChipState extends State<SystemHealthChip> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.health.status) {
      case 'NOMINAL': return AppColors.stateLive;
      case 'DEGRADED': return AppColors.stateStale;
      case 'MISFIRE': return AppColors.stateLocked;
      case 'CALIBRATING': return AppColors.textPrimary;
      case 'UNAVAILABLE': return AppColors.stateLocked;
      default: return AppColors.textDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            if (widget.isFounder) {
              setState(() => _expanded = !_expanded);
            }
          },
          child: Container(
            color: _statusColor.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.health.status,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (widget.health.status != 'NOMINAL')
                  Text(
                     widget.health.reason,
                     style: TextStyle(color: _statusColor, fontSize: 12),
                  ),
                if (widget.isFounder) ...[
                   const SizedBox(width: 8),
                   Icon(
                     _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                     color: AppColors.textDisabled,
                     size: 16,
                   )
                ]
              ],
            ),
          ),
        ),
        if (_expanded && widget.isFounder)
          Container(
            color: AppColors.surface1,
            padding: const EdgeInsets.all(12),
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text("FOUNDER FORENSIC VIEW", style: TextStyle(color: AppColors.textDisabled, fontSize: 10, letterSpacing: 1.5)),
                 const SizedBox(height: 8),
                 _row("Last Run ID", widget.health.lastRunId ?? "N/A"),
                 _row("Artifact Age", "${widget.health.artifactAgeMinutes} mins"),
                 _row("Rec. Action", widget.health.recommendedAction),
                 _row("Timestamp", widget.health.timestampUtc ?? "N/A"),
                 const Divider(color: AppColors.borderSubtle),
                 _row("Reason", widget.health.reason),
               ],
            ),
          )
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textDisabled, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'))),
        ],
      ),
    );
  }
}
