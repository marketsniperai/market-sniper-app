import 'package:flutter/material.dart';
import '../../../models/war_room_snapshot.dart';
import '../../../models/system_health_snapshot.dart';
import '../../war_room_tile.dart';
import '../war_room_tile_meta.dart';
import '../../../theme/app_colors.dart';

class ServiceHoneycomb extends StatelessWidget {
  final WarRoomSnapshot snapshot;
  final bool loading;
  final bool showSources;

  const ServiceHoneycomb({
    super.key,
    required this.snapshot,
    required this.loading,
    this.showSources = false,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("WARROOM_ZONE Z2 build");
    try {
      final width = MediaQuery.of(context).size.width;
      // Responsive Breakpoints: <520 (2), 520-820 (3), 820-1200 (4), >1200 (6)
      final int crossAxisCount = width < 520 ? 2 : width < 820 ? 3 : width < 1200 ? 4 : 6;
      final double tileHeight = 48.0; // Firm Lock

      if (loading) {
        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: tileHeight,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const WarRoomTile(
              title: "LOADING",
              status: WarRoomTileStatus.loading,
              subtitle: [],
            ),
            childCount: 9,
          ),
        );
      }

      final tiles = [
        _buildHealthTile(),
        _buildAutopilotTile(),
        _buildMisfireTile(),
        _buildHousekeeperTile(),
        _buildIronTile(),
        _buildReplayIntegrityTile(),
        _buildUniverseTile(),
        _buildLKGTile(),
        _buildFindingsTile(),
      ];

      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: tileHeight,
        ),
        delegate: SliverChildListDelegate(tiles),
      );
    } catch (e) {
      // D53.6B.1: Never Blank
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(8),
          color: AppColors.textPrimary.withValues(alpha: 0.1),
          child: Text("HONEYCOMB ERROR: $e", style: TextStyle(color: AppColors.stateStale, fontSize: 10)),
        ),
      );
    }
  }

  Widget _buildHealthTile() {
    WarRoomTileStatus status = WarRoomTileStatus.nominal;
    if (snapshot.osHealth.status == HealthStatus.locked) {
      status = WarRoomTileStatus.incident;
    }

    return WarRoomTile(
      title: "OS HEALTH",
      status: status,
      subtitle: [
        snapshot.osHealth.status.toString().split('.').last.toUpperCase()
      ],
      compact: true,
      meta: WarRoomTileRegistry.osHealth,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildAutopilotTile() {
    if (!snapshot.autopilot.isAvailable) {
      return WarRoomTile(
        title: "AUTOPILOT",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.autopilot,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "AUTOPILOT",
      status: WarRoomTileStatus.nominal, // Derived logic simplified
      subtitle: [snapshot.autopilot.mode],
      compact: true,
      meta: WarRoomTileRegistry.autopilot,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildMisfireTile() {
    if (!snapshot.misfire.isAvailable) {
      return WarRoomTile(
        title: "MISFIRE",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.misfire,
        showSourceOverlay: showSources,
      );
    }

    WarRoomTileStatus status = WarRoomTileStatus.nominal;
    if (snapshot.misfire.status == "MISFIRE" ||
        snapshot.misfire.status == "LOCKED") {
      status = WarRoomTileStatus.incident;
    } else if (snapshot.misfire.status == "DEGRADED") {
      status = WarRoomTileStatus.degraded;
    }

    return WarRoomTile(
      title: "MISFIRE",
      status: status,
      subtitle: [snapshot.misfire.status],
      compact: true,
      meta: WarRoomTileRegistry.misfire,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildHousekeeperTile() {
    if (!snapshot.housekeeper.isAvailable) {
      return WarRoomTile(
        title: "HOUSEKEEPER",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.housekeeper,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "HOUSEKEEPER",
      status: WarRoomTileStatus.nominal,
      subtitle: [snapshot.housekeeper.result],
      compact: true,
      meta: WarRoomTileRegistry.housekeeper,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildIronTile() {
    if (!snapshot.iron.isAvailable) {
      return WarRoomTile(
        title: "IRON OS",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.iron,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "IRON OS",
      status: snapshot.iron.status == "ROLLBACK"
          ? WarRoomTileStatus.degraded
          : WarRoomTileStatus.nominal,
      subtitle: [snapshot.iron.state],
      compact: true,
      meta: WarRoomTileRegistry.iron,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildReplayIntegrityTile() {
    if (!snapshot.replay.isAvailable) {
      return WarRoomTile(
        title: "REPLAY",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.replay,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "REPLAY",
      status: snapshot.replay.valid
          ? WarRoomTileStatus.nominal
          : WarRoomTileStatus.incident,
      subtitle: [snapshot.replay.valid ? "VALID" : "INVALID"],
      compact: true,
      meta: WarRoomTileRegistry.replay,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildUniverseTile() {
    if (!snapshot.universe.isAvailable) {
      return WarRoomTile(
        title: "UNIVERSE",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.universe,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "UNIVERSE",
      status: WarRoomTileStatus.nominal,
      subtitle: [snapshot.universe.core],
      compact: true,
      meta: WarRoomTileRegistry.universe,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildLKGTile() {
    if (!snapshot.lkg.isAvailable) {
      return WarRoomTile(
        title: "IRON LKG",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.lkg,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "IRON LKG",
      status: snapshot.lkg.valid
          ? WarRoomTileStatus.nominal
          : WarRoomTileStatus.incident,
      subtitle: [snapshot.lkg.valid ? "VALID" : "INVALID"],
      compact: true,
      meta: WarRoomTileRegistry.lkg,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildFindingsTile() {
    // FindingsSnapshot always available by definition (empty list if unknown)
    return WarRoomTile(
      title: "FINDINGS",
      status: snapshot.findings.findings.isNotEmpty
          ? WarRoomTileStatus.degraded
          : WarRoomTileStatus.nominal,
      subtitle: ["${snapshot.findings.findings.length} Pending"],
      compact: true,
      meta: WarRoomTileRegistry.findings,
      showSourceOverlay: showSources,
    );
  }
}
