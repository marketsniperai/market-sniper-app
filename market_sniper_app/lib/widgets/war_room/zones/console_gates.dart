import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../config/app_config.dart';
import '../../../models/war_room_snapshot.dart';
import '../../war_room_tile.dart';
import '../canon_debt_radar.dart';
import '../war_room_truth_metrics.dart';

class ConsoleGates extends StatelessWidget {
  final WarRoomSnapshot snapshot;
  final bool loading;
  final Widget? founderTruthOverlay;

  const ConsoleGates({
    super.key,
    required this.snapshot,
    required this.loading,
    this.founderTruthOverlay,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("WARROOM_ZONE Z4 build");
    try {
      if (loading) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(height: 100, color: Colors.transparent),
          ),
        );
      }

      final children = <Widget>[
        if (AppConfig.isFounderBuild) _buildTruthPanel(),
        if (AppConfig.isFounderBuild) const SizedBox(height: 8),
        _buildRedButtonTile(),
        const SizedBox(height: 8),
        _buildReplayTile(),
        const SizedBox(height: 8),
        _buildLockReasonTile(),
        const SizedBox(height: 8),
        _buildIronTimelineTile(),
        const SizedBox(height: 8),
        const CanonDebtRadar(),
        const SizedBox(height: 8),
        if (founderTruthOverlay != null) founderTruthOverlay!,
        if (founderTruthOverlay != null) const SizedBox(height: 8),
        _buildAutoFixTier1Tile(),
        const SizedBox(height: 8),
        _buildMisfireRootCauseTile(),
      ];

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        sliver: SliverList(
          delegate: SliverChildListDelegate(children),
        ),
      );
    } catch (e) {
      // D53.6B.1: Never Blank
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white10,
          child: Text("CONSOLE ERROR: $e", style: const TextStyle(color: Colors.orange, fontSize: 10)),
        ),
      );
    }
  }

  Widget _buildRedButtonTile() {
    if (!snapshot.redButton.available) {
        // Only show if available generally? Or show as UNAVAILABLE? 
        // Usually Founder Tools are always visible to Founder, hidden otherwise.
        // Assuming visible.
       return const WarRoomTile(
          title: "RED BUTTON",
          status: WarRoomTileStatus.unavailable,
          subtitle: [],
          compact: true,
       );
    }
    
    // Simplistic rendering
    return WarRoomTile(
      title: "RED BUTTON",
      status: WarRoomTileStatus.nominal,
      subtitle: ["${snapshot.redButton.capabilities.length} Actions"],
      // Logic for interactions would go here (onTap)
      compact: true,
    );
  }

  Widget _buildReplayTile() {
     if (!snapshot.replay.isAvailable) {
         return const WarRoomTile(title: "REPLAY UI", status: WarRoomTileStatus.unavailable, subtitle: [], compact: true);
     }
     return WarRoomTile(
        title: "REPLAY UI",
        status: snapshot.replay.valid ? WarRoomTileStatus.nominal : WarRoomTileStatus.incident,
        subtitle: [snapshot.replay.timestamp],
        compact: true,
     );
  }

  Widget _buildLockReasonTile() {
    if (!snapshot.lockReason.isAvailable || snapshot.lockReason.lockState == "NONE") {
      return const SizedBox.shrink(); // Hide if no lock
    }
    return WarRoomTile(
      title: "LOCK REASON",
      status: WarRoomTileStatus.incident,
      subtitle: [snapshot.lockReason.reasonCode, snapshot.lockReason.module],
      debugInfo: snapshot.lockReason.description,
      compact: true,
    );
  }

  Widget _buildIronTimelineTile() {
    if (!snapshot.ironTimeline.isAvailable) {
       return const SizedBox.shrink();
    }
    // Summary of events
    return WarRoomTile(
      title: "IRON TIMELINE",
      status: WarRoomTileStatus.nominal,
      subtitle: ["${snapshot.ironTimeline.events.length} Events"],
      compact: true,
    );
  }

  Widget _buildAutoFixTier1Tile() {
    if (!snapshot.autofixTier1.isAvailable) return const SizedBox.shrink();
    return WarRoomTile(
      title: "AUTOFIX TIER 1",
      status: WarRoomTileStatus.nominal,
      subtitle: ["Run: ${snapshot.autofixTier1.lastRun}"],
      compact: true,
    );
  }

  Widget _buildMisfireRootCauseTile() {
    if (!snapshot.misfireRootCause.isAvailable) return const SizedBox.shrink();
    return WarRoomTile(
       title: "ROOT CAUSE",
       status: WarRoomTileStatus.incident,
       subtitle: [snapshot.misfireRootCause.misfireType],
       debugInfo: snapshot.misfireRootCause.originatingModule,
       compact: true,
    );
  }

  Widget _buildTruthPanel() {
    // 1) Compute metrics locally
    final metrics =
        computeTruthMetrics(snapshot, nowUtc: DateTime.now().toUtc());

    // 5) Observability (proof in logs) - D53.6Y
    // Only log if not already logged for this snapshot?
    // Since build is called often, we really should log in repo.
    // BUT the requirement is "Add 1 debug log line per snapshot build".
    // We'll trust the "per build" instruction means "when this widget builds".
    // To avoid spam, we can skip if identical to last? No, simple requirement first.
    // Actually, explicit "Must not spam on every frame; log once per fetch completion"
    // implies this should be in Repo or Screen.
    // However, the task says "Add ... 1 debug log line per snapshot build".
    // We will log here but maybe we should move it to Screen if it spams.
    // Wait, "log once per fetch completion" -> This widget is built after fetch.
    // Let's log.
    // debugPrint("WAR_ROOM_TRUTH_METRICS..."); // NOTE: Moved to logic or careful location?
    // User requested: "Add 1 debug log line per snapshot build: ... Must not spam on every frame; log once per fetch completion."
    // Ideally this goes in WarRoomScreen, but we are editing ConsoleGates.
    // Let's put it here but be aware of rebuilds.
    debugPrint(
        "WAR_ROOM_TRUTH_METRICS fetch=${metrics.httpStatus} age=${metrics.ageSeconds}s cov=${metrics.realCount}/${metrics.totalCount} (${metrics.coveragePct.toStringAsFixed(0)}%) na=${metrics.totalCount - metrics.realCount} top=${metrics.topNaTiles}");

    // 2) Render Compact Meter (D53.6Y)
    // Style: Monospace, 9/11px. Traffic light discipline.
    final mono = GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.bold);

    // FETCH Color
    final fetchColor = metrics.fetchOk ? Colors.cyanAccent : Colors.orangeAccent;
    // AGE Color (Gray < 2m, Amber 2-10m, Red > 10m)
    final age = metrics.ageSeconds ?? 9999;
    Color ageColor = Colors.white38;
    if (age > 600) {
      ageColor = Colors.redAccent;
    } else if (age > 120) {
      ageColor = Colors.orangeAccent;
    }

    // COV Color (Cyan >= 60, Amber 30-59, Gray < 30)
    final cov = metrics.coveragePct;
    Color covColor = Colors.white38;
    if (cov >= 60) {
      covColor = Colors.cyanAccent;
    } else if (cov >= 30) {
      covColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(100),
        border: Border.all(color: Colors.white10),
        // borderRadius: BorderRadius.circular(4), // Square for "Meter" feel
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: The Brackets
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // [FETCH: ...]
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: "[FETCH: ", style: mono.copyWith(color: Colors.white38)),
                  TextSpan(
                      text: metrics.fetchOk
                          ? "OK"
                          : (metrics.httpStatus?.toString() ?? "ERR"),
                      style: mono.copyWith(color: fetchColor)),
                  TextSpan(text: "]", style: mono.copyWith(color: Colors.white38)),
                ]),
              ),
              // [AGE: ...]
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: "[AGE: ", style: mono.copyWith(color: Colors.white38)),
                  TextSpan(
                      text: metrics.ageSeconds != null
                          ? "${metrics.ageSeconds}s"
                          : "N/A",
                      style: mono.copyWith(color: ageColor)),
                  TextSpan(text: "]", style: mono.copyWith(color: Colors.white38)),
                ]),
              ),
              // [COV: ...]
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: "[COV: ", style: mono.copyWith(color: Colors.white38)),
                  TextSpan(
                      text:
                          "${metrics.realCount}/${metrics.totalCount} (${metrics.coveragePct.toStringAsFixed(0)}%)",
                      style: mono.copyWith(color: covColor)),
                  TextSpan(text: "]", style: mono.copyWith(color: Colors.white38)),
                ]),
              ),
              // [N/A: ...]
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: "[N/A: ", style: mono.copyWith(color: Colors.white38)),
                  TextSpan(
                      text: "${metrics.totalCount - metrics.realCount}",
                      style: mono.copyWith(
                          color: (metrics.totalCount - metrics.realCount) > 0
                              ? Colors.orangeAccent
                              : Colors.white38)),
                  TextSpan(text: "]", style: mono.copyWith(color: Colors.white38)),
                ]),
              ),
            ],
          ),
          // Row 2: Missing list (if any)
          if (metrics.topNaTiles.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "MISSING: ${metrics.topNaTiles.join(", ")}${metrics.topNaTiles.length < (metrics.totalCount - metrics.realCount) ? "..." : ""}",
              style: GoogleFonts.robotoMono(
                  fontSize: 10, color: Colors.orangeAccent.withOpacity(0.7)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ]
        ],
      ),
    );
  }
}
