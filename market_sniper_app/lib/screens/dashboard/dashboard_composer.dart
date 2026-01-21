import 'package:flutter/material.dart';
import '../../models/dashboard_payload.dart';
import '../../models/system_health.dart';
import '../../models/system_health_snapshot.dart';
import '../../models/last_run_snapshot.dart';
import '../../logic/data_state_resolver.dart';
import '../../logic/dashboard_degrade_policy.dart';
// import '../../config/app_config.dart';
import '../../theme/app_colors.dart';
// import '../../theme/app_typography.dart';
// import '../../ui/components/dashboard_card.dart';
import '../../ui/tokens/dashboard_spacing.dart';

// Widgets to compose
import '../../widgets/founder_banner.dart';
import '../../widgets/degrade_banner.dart';
import '../../widgets/session_window_strip.dart';
import '../../widgets/os_health_widget.dart';
import '../../widgets/last_run_widget.dart';
import '../../widgets/system_health_chip.dart';
import '../../widgets/dashboard_widgets.dart'; // For renderWidget

class DashboardComposer {
  final DashboardPayload? dashboard;
  final SystemHealth? health; // Legacy
  final SystemHealthSnapshot healthSnapshot;
  final LastRunSnapshot lastRunSnapshot;
  final bool isFounder;
  final ResolvedDataState? resolvedState;
  final DegradeContext degradeContext;

  DashboardComposer({
    required this.dashboard,
    required this.health,
    required this.healthSnapshot,
    required this.lastRunSnapshot,
    required this.isFounder,
    required this.resolvedState,
    required this.degradeContext,
  });

  List<Widget> buildList(BuildContext context) {
    final List<Widget> items = [];

    // 1. Founder Banner (Access: Top of stack)
    if (isFounder) {
      items.add(const FounderBanner());
      
      // SSOT Debug Row
      final asOf = dashboard?.asOfUtc?.toLocal().toString() ?? "UNKNOWN";
      final runId = dashboard?.runId ?? "UNKNOWN";
      items.add(
        Padding(
          padding: DashboardSpacing.founderSsoT,
          child: Text(
            "SSOT: ${dashboard?.systemStatus ?? 'UNKNOWN'} | AS OF: $asOf | RUN: $runId",
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontFamily: 'monospace',
              fontSize: 9, 
            ),
          ),
        ),
      );
    }

    // 2. Degrade Banner (Critical Alerts)
    items.add(DegradeBanner(
      degradeContext: degradeContext,
      isFounder: isFounder,
    ));

    // 3. Session Window (Always Visible Anchor)
    // Not wrapped in Card, it's a specific strip
    if (resolvedState != null) {
      items.add(Padding(
        padding: DashboardSpacing.bottomGap,
        child: SessionWindowStrip(
          dataState: resolvedState!,
          healthSnapshot: healthSnapshot, // D45.18
        ),
      ));
    }

    // 4. OS Health (Command Center Critical)
    items.add(OSHealthWidget(
      health: healthSnapshot,
      isFounder: isFounder,
    ));
    // OSHealthWidget usually wraps itself in Card-like structure. 
    // We should strictly ensure it complies or wrap it?
    // Current OSHealthWidget implementation uses Container with decoration. 
    // Ideally we leave it as is if it looks correct, or wrap it. 
    // Let's add spacing after.
    items.add(const SizedBox(height: DashboardSpacing.gap));


    // 5. Last Run (Pipeline Transparency)
    items.add(LastRunWidget(
      lastRun: lastRunSnapshot,
      isFounder: isFounder,
    ));
    items.add(const SizedBox(height: DashboardSpacing.gap));


    // 6. Usage Chips (Navigation / Quick Filter)
    items.add(_buildCategoryChips());
    items.add(const SizedBox(height: DashboardSpacing.gap));

    // 7. Legacy Health Chip (If exists)
    if (health != null) {
      items.add(Padding(
        padding: DashboardSpacing.bottomGap,
        child: SystemHealthChip(
          health: health!,
          isFounder: isFounder,
        ),
      ));
    }

    // 8. Header Info
    final sysStatus = dashboard?.systemStatus.toString().split('.').last.toUpperCase() ?? "UNKNOWN";
    items.add(Text("STATUS: $sysStatus", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentCyan)));
    items.add(Text("MSG: ${dashboard?.message ?? 'N/A'}", style: const TextStyle(color: AppColors.textPrimary)));
    items.add(const SizedBox(height: DashboardSpacing.gap));

    // 9. Dynamic Widgets
    if (dashboard != null) {
      for (var w in dashboard!.widgets) {
        items.add(Padding(
          padding: DashboardSpacing.bottomGap,
          child: renderWidget(w), // renderWidget currently returns Cards.
        ));
      }
    }


    // 10. Footer
    items.add(const SizedBox(height: DashboardSpacing.sectionGap));
    items.add(Center(
      child: Text(
        "Generated: ${dashboard?.generatedAt ?? 'Unknown'}",
        style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
      ),
    ));
    items.add(const SizedBox(height: 64)); // Bottom padding for FAB/Tags

    return items;
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
           _buildStubChip("Stocks", true),
           const SizedBox(width: DashboardSpacing.gapSmall),
           _buildStubChip("Options", false),
           const SizedBox(width: DashboardSpacing.gapSmall),
           _buildStubChip("News", false),
           const SizedBox(width: DashboardSpacing.gapSmall),
           _buildStubChip("Macro", false),
        ],
      ),
    );
  }

  Widget _buildStubChip(String label, bool active) {
    return Container(
      padding: DashboardSpacing.chipPadding,
      decoration: BoxDecoration(
        color: active ? AppColors.accentCyan.withValues(alpha: 0.2) : AppColors.surface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? AppColors.accentCyan : Colors.transparent),
      ),
      child: Text(label, style: TextStyle(color: active ? AppColors.accentCyan : AppColors.textSecondary, fontSize: 12)),
    );
  }
}
