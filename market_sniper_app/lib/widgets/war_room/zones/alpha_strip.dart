import 'package:flutter/material.dart';
import '../../../models/war_room_snapshot.dart';
import '../../war_room_tile.dart';
import '../war_room_tile_meta.dart';

class AlphaStrip extends StatelessWidget {
  final WarRoomSnapshot snapshot;
  final bool loading;
  final bool showSources;

  const AlphaStrip({
    super.key,
    required this.snapshot,
    required this.loading,
    this.showSources = false,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("WARROOM_ZONE Z3 build");
    try {
      final width = MediaQuery.of(context).size.width;
      // Responsive Breakpoints: <520 (2), 520-820 (2), 820-1200 (4), >1200 (4)
      final int crossAxisCount = width < 520 ? 2 : width < 820 ? 2 : width < 1200 ? 4 : 4;
      final double tileHeight = 42.0; // Ticker Lock

      if (loading) {
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          sliver: SliverGrid(
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
                compact: true,
              ),
              childCount: 4,
            ),
          ),
        );
      }

      final tiles = [
        _buildOptionsTile(),
        _buildEvidenceTile(),
        _buildMacroTile(),
        _buildDriftTile(),
      ];

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: tileHeight,
          ),
          delegate: SliverChildListDelegate(tiles),
        ),
      );
    } catch (e) {
      // D53.6B.1: Never Blank
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white10,
          child: Text("ALPHA ERROR: $e", style: const TextStyle(color: Colors.orange, fontSize: 10)),
        ),
      );
    }
  }

  Widget _buildOptionsTile() {
    if (!snapshot.options.isAvailable) {
      return WarRoomTile(
        title: "OPTIONS",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.options,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "OPTIONS",
      status: WarRoomTileStatus.nominal,
      subtitle: [snapshot.options.status, snapshot.options.ivRegime],
      compact: true,
      meta: WarRoomTileRegistry.options,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildEvidenceTile() {
    if (!snapshot.evidence.isAvailable) {
      return WarRoomTile(
        title: "EVIDENCE",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.evidence,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "EVIDENCE",
      status: WarRoomTileStatus.nominal,
      subtitle: [
        "${snapshot.evidence.sampleSize} Samples",
        snapshot.evidence.headline
      ],
      compact: true,
      meta: WarRoomTileRegistry.evidence,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildMacroTile() {
    if (!snapshot.macro.isAvailable) {
      return WarRoomTile(
        title: "MACRO",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.macro,
        showSourceOverlay: showSources,
      );
    }
    return WarRoomTile(
      title: "MACRO",
      status: WarRoomTileStatus.nominal,
      subtitle: [snapshot.macro.status],
      compact: true,
      meta: WarRoomTileRegistry.macro,
      showSourceOverlay: showSources,
    );
  }

  Widget _buildDriftTile() {
    if (!snapshot.drift.isAvailable) {
      return WarRoomTile(
        title: "DRIFT",
        status: WarRoomTileStatus.unavailable,
        subtitle: [],
        compact: true,
        meta: WarRoomTileRegistry.drift,
        showSourceOverlay: showSources,
      );
    }
    
    // Status logic
    WarRoomTileStatus status = WarRoomTileStatus.nominal;
    if (snapshot.drift.status != "NOMINAL" && snapshot.drift.status != "OK" && snapshot.drift.status != "N_A") {
        status = WarRoomTileStatus.degraded;
    }

    return WarRoomTile(
      title: "DRIFT",
      status: status,
      subtitle: ["Offset: ${snapshot.drift.systemClockOffsetMs}ms"],
      compact: true,
      meta: WarRoomTileRegistry.drift,
      showSourceOverlay: showSources,
    );
  }
}
