import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/war_room_tile.dart';
import '../repositories/war_room_repository.dart';
import '../models/war_room_snapshot.dart';
import '../models/system_health_snapshot.dart';
import '../services/api_client.dart';

import '../logic/war_room_refresh_controller.dart';
import '../logic/war_room_degrade_policy.dart';
import '../config/app_config.dart';
import '../widgets/war_room/replay_control_tile.dart'; // D41.03 Replay UI
// Legacy but kept if needed, though replaced mostly
import '../widgets/war_room/invite_logic_tile.dart'; // DXX.WELCOME.02
import '../widgets/war_room/canon_debt_radar.dart'; // D45.CANON.DEBT_RADAR.V1

class WarRoomScreen extends StatefulWidget {
  const WarRoomScreen({super.key});

  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen>
    with WidgetsBindingObserver {
  late WarRoomRepository _repo;
  late WarRoomRefreshController _refreshController;

  WarRoomSnapshot _snapshot = WarRoomSnapshot.initial;
  bool _loading = true; // Initial load spinner
  bool _silentRefreshing = false; // For subtle indicator

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = WarRoomRepository(api: ApiClient());

    _refreshController = WarRoomRefreshController(onRefresh: _handleRefresh);

    // Initial Load
    _loadData(); // This handles the first spinner

    // Start Governance (will schedule next)
    _refreshController.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _refreshController.pause();
    } else if (state == AppLifecycleState.resumed) {
      _refreshController.resume();
    }
  }

  // Initial heavy load (spinner)
  Future<void> _loadData() async {
    // Spinner logic handled by _loading var init
    // Just force a refresh cycle
    // Note: Controller schedules *next*, but we want one *now*.
    // We can manually call handleRefresh or just rely on controller start?
    // Controller start only schedules *next*.
    // We want immediate data.

    await _handleRefresh(initial: true);
  }

  // The core refresh logic callback
  Future<void> _handleRefresh({bool initial = false}) async {
    if (initial) {
      setState(() => _loading = true);
    } else {
      setState(() => _silentRefreshing = true);
    }

    try {
      final data = await _repo.fetchSnapshot();

      // Governance Check
      bool backoff = false;
      // OS Health Locked?
      if (data.osHealth.status == HealthStatus.locked) backoff = true;
      // Any tile unavailable?
      if (!data.osHealth.status.toString().isNotEmpty || // Should not happen
          !data.autopilot.isAvailable ||
          !data.misfire.isAvailable ||
          !data.housekeeper.isAvailable ||
          !data.iron.isAvailable ||
          !data.universe.isAvailable) {
        backoff = true;
      }

      _refreshController.reportEffectiveState(backoff);

      if (mounted) {
        setState(() {
          _snapshot = data;
          _loading = false;
          _silentRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _silentRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: () => _refreshController.requestManualRefresh(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "WAR ROOM",
                style: AppTypography.headline(context).copyWith(
                  color: AppColors.neonCyan,
                  letterSpacing: 2.0,
                ),
              ),
              if (AppConfig.isFounderBuild && _silentRefreshing)
                Text(
                  "Refeshing...",
                  style: AppTypography.caption(context).copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderSubtle, height: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => await _refreshController.requestManualRefresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatusBanner(),
                  AppSpacing.gapCard,
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.cardGap,
                mainAxisSpacing: AppSpacing.cardGap,
                childAspectRatio: 1.1,
                children: [
                  _buildHealthTile(),
                  _buildAutopilotTile(),
                  _buildMisfireTile(),
                  _buildHousekeeperTile(),
                  _buildIronTile(),
                  _buildIronTimelineTile(),
                  _buildLKGTile(),
                  _buildDecisionPathTile(),
                  _buildDriftTile(),
                  _buildReplayIntegrityTile(),
                  _buildReplayTile(), // D41.03
                  _buildLockReasonTile(),
                  _buildCoverageTile(),
                  _buildFindingsTile(),
                  _buildBeforeAfterTile(),
                  _buildAutoFixTier1Tile(),
                  _buildAutoFixDecisionPathTile(),
                  _buildMisfireRootCauseTile(),
                  _buildSelfHealConfidenceTile(),
                  _buildSelfHealWhatChangedTile(),
                  _buildCooldownTransparencyTile(),
                  _buildRedButtonTile(),
                  _buildMisfireTier2Tile(),
                  _buildUniverseTile(),
                  _buildOptionsTile(), // D36.3
                  _buildMacroTile(), // D36.5
                  _buildEvidenceTile(), // D36.4
                  const InviteLogicTile(), // DXX.WELCOME.02
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AppSpacing.gapCard,
                  _buildIronHistorySection(),
                  AppSpacing.gapSection,
                  const CanonDebtRadar(), // D45.CANON.DEBT_RADAR.V1
                  if (AppConfig.isFounderBuild) ...[
                    AppSpacing.gapSection,
                    _buildFounderTruth(),
                  ],
                  const SizedBox(height: 32), // Bottom padding
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_loading) return const SizedBox.shrink();

    final eval = WarRoomDegradePolicy.evaluate(_snapshot);
    if (eval.state == WarRoomGlobalState.nominal) {
      return const SizedBox.shrink();
    }

    Color bgColor = AppColors.surface1;
    Color textColor = AppColors.textPrimary;
    IconData icon = Icons.info_outline;

    switch (eval.state) {
      case WarRoomGlobalState.degraded:
        bgColor = AppColors.stateStale.withValues(alpha: 0.1);
        textColor = AppColors.stateStale;
        icon = Icons.warning_amber_rounded;
        break;
      case WarRoomGlobalState.incident:
        bgColor = AppColors.stateLocked.withValues(alpha: 0.1);
        textColor = AppColors.stateLocked;
        icon = Icons.error_outline;
        break;
      case WarRoomGlobalState.unavailable:
        bgColor = AppColors.textDisabled.withValues(alpha: 0.1);
        textColor = AppColors.stateLocked;
        icon = Icons.cloud_off;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eval.message,
                  style: AppTypography.label(context)
                      .copyWith(color: textColor, fontWeight: FontWeight.bold),
                ),
                if (eval.issues.isNotEmpty)
                  Text(
                    eval.issues.join(", "),
                    style: AppTypography.caption(context)
                        .copyWith(color: textColor.withValues(alpha: 0.8)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFounderTruth() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          "FOUNDER TRUTH SURFACE",
          style: AppTypography.caption(context).copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _truthRow("OS Health", _snapshot.osHealth.status.toString(),
                    "unified"),
                _truthRow("Misfire", _snapshot.misfire.source,
                    _snapshot.misfire.isAvailable ? "OK" : "MISSING"),
                _truthRow("Iron OS", _snapshot.iron.source,
                    _snapshot.iron.isAvailable ? "OK" : "MISSING"),
                _truthRow(
                    "Last Refresh",
                    _refreshController.lastRefreshTime?.toIso8601String() ??
                        "N/A",
                    "local"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _truthRow(String label, String value, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption(context)),
          Expanded(
            child: Text(
              "$value ($status)",
              style: AppTypography.caption(context).copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontFamily: GoogleFonts.robotoMono().fontFamily,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTile() {
    final h = _snapshot.osHealth;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> subtitle = [];

    if (!_loading) {
      switch (h.status) {
        case HealthStatus.nominal:
          status = WarRoomTileStatus.nominal;
          break;
        case HealthStatus.degraded:
          status = WarRoomTileStatus.degraded;
          break;
        case HealthStatus.misfire:
          status = WarRoomTileStatus.incident;
          break;
        case HealthStatus.locked:
          status = WarRoomTileStatus.incident;
          break;
        case HealthStatus.unknown:
          status = WarRoomTileStatus.unavailable;
          break;
      }
      subtitle = [h.status.toString().split('.').last.toUpperCase()];
      if (h.ageSeconds > 0) subtitle.add("${h.ageSeconds}s ago");
    }

    return WarRoomTile(
      title: "OS HEALTH",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: subtitle,
      debugInfo: "Source: unified (health_ext+misfire)",
    );
  }

  Widget _buildAutopilotTile() {
    final a = _snapshot.autopilot;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!a.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // 1. Status Determination
        if (a.mode == "SAFE_AUTOPILOT" || a.mode == "FULL_AUTOPILOT") {
          status = WarRoomTileStatus.nominal;
        } else if (a.mode == "SHADOW") {
          status = WarRoomTileStatus.nominal;
        } else if (a.mode == "OFF") {
          // Housekeeper separate now, so OFF is degraded/inactive
          status = WarRoomTileStatus.degraded;
        } else {
          status = WarRoomTileStatus.nominal;
        }

        if (a.mode == "UNAVAILABLE") status = WarRoomTileStatus.unavailable;

        // 2. Build Rows
        lines.add("MODE: ${a.mode}");
        lines.add("AUTOFIX: ${a.stage}");

        String lastAction = a.lastAction;
        if (lastAction.length > 15) {
          lastAction = "${lastAction.substring(0, 15)}...";
        }

        String time = a.lastActionTime;
        if (time.contains("T")) time = time.split("T").last.split(".").first;
        lines.add("LAST: $lastAction @ $time");

        if (a.cooldownRemaining > 0) {
          lines.add("COOLDOWN: ${a.cooldownRemaining}s");
        }
      }
    }

    return WarRoomTile(
      title: "CONTROL PLANE",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${a.source}",
    );
  }

  Widget _buildMisfireTile() {
    final m = _snapshot.misfire;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!m.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        if (m.status == "NOMINAL") {
          status = WarRoomTileStatus.nominal;
        } else if (m.status == "MISFIRE" || m.status == "LOCKED") {
          status = WarRoomTileStatus.incident;
        } else {
          status = WarRoomTileStatus.degraded;
        }

        lines.add("STATUS: ${m.status}");

        String last = m.lastMisfire;
        if (last.contains("T")) last = last.split("T").last.split(".").first;
        lines.add("LAST: $last");

        final recState = m.autoRecovery ? "ON" : "OFF";
        lines.add("RECOVERY: $recState (${m.recoveryState})");

        String lastAct = m.lastAction;
        if (lastAct.length > 20) lastAct = "${lastAct.substring(0, 20)}...";
        lines.add("ACT: $lastAct");

        if (m.cooldown > 0) {
          lines.add("COOLDOWN: ${m.cooldown}s");
        }

        if (m.proof != "N/A" && m.proof != "UNKNOWN") {
          lines.add("PROOF: ${m.proof}");
        }

        if (m.note.isNotEmpty) {
          String note = m.note;
          if (note.length > 20) note = "${note.substring(0, 20)}...";
          lines.add("NOTE: $note");
        }
      }
    }

    return WarRoomTile(
      title: "MISFIRE MONITOR",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${m.source}",
    );
  }

  Widget _buildHousekeeperTile() {
    final hk = _snapshot.housekeeper;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!hk.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Evaluate tile status from result string
        // result can be "SUCCESS (5)", "PARTIAL", "FAILED", "NOOP", "UNKNOWN"
        String res = hk.result.split(' ').first; // Extract basic status

        if (res == "SUCCESS") {
          status = WarRoomTileStatus.nominal;
        } else if (res == "NOOP")
          status = WarRoomTileStatus
              .nominal; // NOOP is fine (e.g. missing plan is safe)
        else if (res == "PARTIAL")
          status = WarRoomTileStatus.degraded;
        else if (res == "FAILED")
          status = WarRoomTileStatus.incident;
        else
          status = WarRoomTileStatus.degraded;

        if (hk.autoRun) {
          lines.add("AUTO: ON");
        } else {
          lines.add("AUTO: OFF"); // Legacy flag or inferred
        }

        String last = hk.lastRun;
        if (last.contains("T")) last = last.split("T").last.split(".").first;
        lines.add("LAST: $last");

        lines.add("STATUS: ${hk.result}");
      }
    }

    return WarRoomTile(
      title: "HOUSEKEEPER",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${hk.source}",
    );
  }

  Widget _buildIronTile() {
    final i = _snapshot.iron;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!i.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Map state to tile status (Mirror)
        switch (i.state) {
          case "NOMINAL":
            status = WarRoomTileStatus.nominal;
            break;
          case "DEGRADED":
            status = WarRoomTileStatus.degraded;
            break;
          case "INCIDENT":
            status = WarRoomTileStatus.incident;
            break;
          case "LOCKED":
            status = WarRoomTileStatus.incident;
            break;
          default:
            status = WarRoomTileStatus.nominal; // Fallback for IDLE/BOOT
        }

        lines.add("STATE: ${i.state}");

        String tick = i.lastTick;
        if (tick.contains("T")) tick = tick.split("T").last.split(".").first;
        lines.add("LAST TICK: $tick");

        if (i.ageSeconds > 0) {
          lines.add("AGE: ${i.ageSeconds}s");
        } else {
          lines.add("AGE: 0s");
        }
      }
    }

    return WarRoomTile(
      title: "IRON OS",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${i.source}",
    );
  }

  Widget _buildIronTimelineTile() {
    final t = _snapshot.ironTimeline;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!t.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        status = WarRoomTileStatus.nominal;

        if (t.events.isEmpty) {
          lines.add("No recent events.");
        } else {
          // Show last 3 events as summary
          int count = 0;
          for (var e in t.events) {
            if (count >= 3) break;
            String ts = e.timestamp;
            if (ts.contains("T")) ts = ts.split("T").last.split(".").first;

            String type = e.type;
            if (type.length > 8) type = type.substring(0, 8);

            lines.add("$ts [$type]");
            count++;
          }
          if (t.events.length > 3) {
            lines.add("... +${t.events.length - 3} more");
          }
        }
      }
    }

    return WarRoomTile(
      title: "TIMELINE (TAIL)",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${t.source}",
    );
  }

  Widget _buildIronHistorySection() {
    final h = _snapshot.ironHistory;
    if (!h.isAvailable && !AppConfig.isFounderBuild) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "IRON OS — STATE HISTORY (LAST 10)",
              style: AppTypography.label(context)
                  .copyWith(color: AppColors.textSecondary),
            ),
            if (!h.isAvailable)
              Text("UNAVAILABLE",
                  style: AppTypography.caption(context).copyWith(
                      color: AppColors.stateLocked,
                      fontWeight: FontWeight.bold))
          ],
        ),
        const SizedBox(height: 12),
        if (!h.isAvailable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stateLocked.withValues(alpha: 0.1),
              border: const Border(
                  left: BorderSide(color: AppColors.stateLocked, width: 4)),
            ),
            child: Text("HISTORY UNAVAILABLE",
                style: AppTypography.caption(context).copyWith(
                    color: AppColors.stateLocked, fontWeight: FontWeight.bold)),
          )
        else
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              itemCount: h.history.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (c, i) {
                final e = h.history[i];
                Color stateColor;
                switch (e.state) {
                  case "NOMINAL":
                    stateColor = AppColors.stateLive;
                    break;
                  case "DEGRADED":
                    stateColor = AppColors.stateStale;
                    break;
                  case "INCIDENT":
                    stateColor = AppColors.stateLocked;
                    break;
                  case "LOCKED":
                    stateColor = AppColors.stateLocked;
                    break;
                  default:
                    stateColor = AppColors.textSecondary;
                }

                String ts = e.timestamp;
                if (ts.contains("T")) ts = ts.split("T").last.split(".").first;

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: stateColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: stateColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(e.state,
                            style: AppTypography.caption(context).copyWith(
                                fontSize: 10,
                                color: stateColor,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Text(ts,
                          style: AppTypography.caption(context).copyWith(
                              fontSize: 9, color: AppColors.textDisabled)),
                    ],
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  Widget _buildLKGTile() {
    final lkg = _snapshot.lkg;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!lkg.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        status =
            lkg.valid ? WarRoomTileStatus.nominal : WarRoomTileStatus.degraded;

        String ts = lkg.timestamp;
        if (ts.contains("T")) ts = ts.split("T").last.split(".").first;

        String hashShort = lkg.hash;
        if (hashShort.length > 8) hashShort = hashShort.substring(0, 8);

        lines.add("HASH: $hashShort");
        lines.add("TIME: $ts");
        lines.add("SIZE: ${lkg.sizeBytes} B");
        lines.add("VALIDITY: ${lkg.valid ? 'VALID' : 'INVALID'}");
      }
    }

    return WarRoomTile(
      title: "IRON LKG",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${lkg.source}",
    );
  }

  Widget _buildDecisionPathTile() {
    final d = _snapshot.decisionPath;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!d.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        status = d.fallbackUsed
            ? WarRoomTileStatus.degraded
            : WarRoomTileStatus.nominal;

        String ts = d.timestamp;
        if (ts.contains("T")) ts = ts.split("T").last.split(".").first;

        lines.add("TIME: $ts");
        lines.add("TYPE: ${d.type}");
        lines.add("FALLBACK: ${d.fallbackUsed}");
        lines.add(
            "REASON: ${d.reason.length > 20 ? "${d.reason.substring(0, 17)}..." : d.reason}");
        if (d.actionTaken != null) {
          lines.add("ACTION: ${d.actionTaken}");
        }
      }
    }

    return WarRoomTile(
      title: "LAST DECISION",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${d.source}",
    );
  }

  Widget _buildDriftTile() {
    final d = _snapshot.drift;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!d.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else if (d.entries.isEmpty) {
        status = WarRoomTileStatus.nominal;
        lines.add("NO DRIFT DETECTED");
      } else {
        status = WarRoomTileStatus.degraded;
        lines.add("${d.entries.length} MISMATCHES");
        for (var i = 0; i < d.entries.length && i < 3; i++) {
          final e = d.entries[i];
          lines.add("${e.component}: ${e.expected} != ${e.observed}");
        }
      }
    }

    return WarRoomTile(
      title: "EXTENDED DRIFT",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${d.source}",
    );
  }

  Widget _buildReplayIntegrityTile() {
    final r = _snapshot.replay;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!r.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        bool anyIssues =
            r.corrupted || r.truncated || r.outOfOrder || r.duplicateEvents;
        status =
            anyIssues ? WarRoomTileStatus.degraded : WarRoomTileStatus.nominal;

        if (!anyIssues) {
          lines.add("INTEGRITY CONFIRMED");
        } else {
          if (r.corrupted) lines.add("CORRUPTED");
          if (r.truncated) lines.add("TRUNCATED");
          if (r.outOfOrder) lines.add("OUT OF ORDER");
          if (r.duplicateEvents) lines.add("DUPLICATE EVENTS");
        }
      }
    }

    return WarRoomTile(
      title: "REPLAY INTEGRITY",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${r.source}",
    );
  }

  Widget _buildOptionsTile() {
    final o = _snapshot.options;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!o.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Map Status Logic
        // status: LIVE => Nominal
        // PROVIDER_DENIED => Degraded (Yellow)
        // PROXY_ESTIMATED => Degraded
        // N_A => Degraded/Info
        if (o.status == 'LIVE') {
          status = WarRoomTileStatus.nominal;
        } else if (o.status == 'CACHE')
          status = WarRoomTileStatus.nominal; // Cache is nominal enough
        else if (o.status == 'PROVIDER_DENIED')
          status = WarRoomTileStatus.degraded;
        else if (o.status == 'PROXY_ESTIMATED')
          status = WarRoomTileStatus.degraded;
        else
          status = WarRoomTileStatus.degraded; // N_A or others

        lines.add("STATUS: ${o.status}");
        // lines.add("COVERAGE: ${o.coverage}"); // Can remove to save space if needed

        if (o.status == 'CACHE') {
          // Maybe show cache age if passed in snapshot? Current snapshot has fallback reason but not raw age.
          // We can infer from fallback reason or just show status.
        }

        if (o.providerAttempted) {
          lines.add("PROV: ${o.providerResult}");
        }

        if (o.fallbackReason != "NONE" && o.fallbackReason != "null") {
          String r = o.fallbackReason;
          if (r.length > 15) r = "${r.substring(0, 15)}...";
          lines.add("ERR: $r");
        }

        String t = o.asOfUtc;
        if (t.contains('T')) t = t.split('T').last.split('.').first;
        lines.add("TIME: $t");
      }
    }

    return WarRoomTile(
      title: "OPTIONS INTEL",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /options_context",
    );
  }

  Widget _buildMacroTile() {
    final m = _snapshot.macro;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!m.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Status mapping
        if (m.status == 'LIVE') {
          status = WarRoomTileStatus.nominal;
        } else if (m.status == 'PARTIAL')
          status = WarRoomTileStatus.degraded;
        else if (m.status == 'N_A')
          status = WarRoomTileStatus.degraded; // Neutral
        else
          status = WarRoomTileStatus.incident;

        lines.add("STATUS: ${m.status}");
        lines.add("RATES: ${m.rates}");
        lines.add("USDOLLAR: ${m.dollar}");
        lines.add("OIL: ${m.oil}");
      }
    }

    return WarRoomTile(
      title: "MACRO CONTEXT",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /macro_context",
    );
  }

  Widget _buildEvidenceTile() {
    final e = _snapshot.evidence;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!e.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Status mapping
        if (e.status == 'LIVE') {
          status = WarRoomTileStatus.nominal;
        } else if (e.status == 'PARTIAL')
          status = WarRoomTileStatus.degraded;
        else if (e.status == 'N_A')
          status = WarRoomTileStatus.degraded; // Neutral
        else
          status = WarRoomTileStatus.incident;

        lines.add("STATUS: ${e.status}");
        lines.add("N: ${e.sampleSize}");

        String h = e.headline;
        if (h.length > 25) h = "${h.substring(0, 25)}...";
        lines.add("HEAD: $h");
      }
    }

    return WarRoomTile(
      title: "EVIDENCE",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /evidence_summary",
    );
  }

  Widget _buildReplayTile() {
    // D41.03 Institutional Day Replay
    // Founder-only interactive tile
    return ReplayControlTile(
      isFounder: AppConfig.isFounderBuild,
    );
  }

  Widget _buildAutoFixTier1Tile() {
    final afx = _snapshot.autofixTier1;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!afx.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Status mapping
        // NOOP/SUCCESS -> NOMINAL
        // PARTIAL -> DEGRADED
        // FAILED -> INCIDENT
        String s = afx.status;
        if (s == "SUCCESS" || s == "NOOP") {
          status = WarRoomTileStatus.nominal;
        } else if (s == "PARTIAL")
          status = WarRoomTileStatus.degraded;
        else if (s == "FAILED")
          status = WarRoomTileStatus.incident;
        else
          status = WarRoomTileStatus.degraded;

        lines.add("STATUS: $s");
        lines.add("PLAN: ${afx.planId}");
        lines.add("EXECUTED: ${afx.actionsExecuted}");

        String ts = afx.lastRun;
        if (ts.contains("T")) ts = ts.split("T").last.split(".").first;
        lines.add("LAST: $ts");
      }
    }

    return WarRoomTile(
      title: "AUTOFIX (TIER 1)",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /lab/os/self_heal/autofix/tier1",
    );
  }

  Widget _buildAutoFixDecisionPathTile() {
    final dp = _snapshot.autofixDecisionPath;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!dp.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Status Mapping
        String overall = dp.status;
        if (overall == "SUCCESS" || overall == "NO_OP") {
          status = WarRoomTileStatus.nominal;
        } else if (overall == "PARTIAL")
          status = WarRoomTileStatus.degraded;
        else if (overall == "FAILED" || overall == "BLOCKED")
          status = WarRoomTileStatus.incident;
        else
          status = WarRoomTileStatus.nominal;

        lines.add("PATH: $overall");
        lines.add("ID: ${dp.runId}");
        lines.add("CTX: ${dp.context}");

        // Action Summary or Detail
        // Show breakdown of outcomes if possible
        int exec = 0;
        int skipped = 0;
        int blocked = 0;

        for (var a in dp.actions) {
          if (a.outcome == "EXECUTED") {
            exec++;
          } else if (a.outcome == "SKIPPED")
            skipped++;
          else if (a.outcome == "BLOCKED" || a.outcome == "REJECTED") blocked++;
        }

        if (dp.actionCount == 0) {
          lines.add("ACTIONS: NONE");
        } else {
          lines.add("EXEC:$exec SKIP:$skipped BLK:$blocked");
        }
      }
    }

    return WarRoomTile(
      title: "AUTOFIX PATH",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /lab/os/self_heal/autofix/decision_path",
    );
  }

  Widget _buildMisfireRootCauseTile() {
    final rc = _snapshot.misfireRootCause;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!rc.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Status Mapping
        if (rc.outcome == "RESOLVED" || rc.outcome == "MITIGATED") {
          status = WarRoomTileStatus.nominal;
        } else if (rc.outcome == "OPEN")
          status = WarRoomTileStatus.incident;
        else if (rc.outcome == "FAILED")
          status = WarRoomTileStatus.degraded;
        else
          status = WarRoomTileStatus.nominal;

        lines.add("TYPE: ${rc.misfireType}");
        lines.add("OUTCOME: ${rc.outcome}");
        lines.add("MOD: ${rc.originatingModule}");

        if (rc.primaryArtifact != null) lines.add("ART: ${rc.primaryArtifact}");
        if (rc.fallbackUsed != null) lines.add("FALLBACK: ${rc.fallbackUsed}");
        if (rc.actionTaken != null) lines.add("ACTION: ${rc.actionTaken}");
      }
    }

    return WarRoomTile(
      title: "MISFIRE ROOT CAUSE",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /lab/os/self_heal/misfire/root_cause",
    );
  }

  Widget _buildSelfHealConfidenceTile() {
    final conf = _snapshot.selfHealConfidence;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!conf.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        // Status Mapping
        if (conf.overall == "HIGH") {
          status = WarRoomTileStatus.nominal;
        } else if (conf.overall == "MED")
          status = WarRoomTileStatus.nominal;
        else if (conf.overall == "LOW")
          status = WarRoomTileStatus.degraded;
        else
          status = WarRoomTileStatus.nominal;

        lines.add("OVERALL: ${conf.overall}");
        // lines.add("RUN: ${conf.runId}");

        if (conf.entries.isEmpty) {
          lines.add("NO ACTIONS RECORDED");
        } else {
          // Show last entry or summary
          final last = conf.entries.last;
          lines.add("${last.engine}: ${last.confidence}");
          lines.add("ACT: ${last.actionCode}");
          if (last.evidence.isNotEmpty) {
            lines.add("EVID: ${last.evidence.join(',')}");
          }
        }
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL CONFIDENCE",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /lab/os/self_heal/confidence",
    );
  }

  Widget _buildSelfHealWhatChangedTile() {
    final wc = _snapshot.selfHealWhatChanged;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!wc.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        status = WarRoomTileStatus.nominal;

        if (wc.summary != null) lines.add("SUM: ${wc.summary}");

        // State Transition
        if (wc.stateTransition != null) {
          final st = wc.stateTransition!;
          lines.add("STATE: ${st.fromState ?? '?'} -> ${st.toState ?? '?'}");
          if (st.unlocked) lines.add("UNLOCKED: TRUE");
        }

        // Artifacts
        if (wc.artifactsUpdated.isEmpty) {
          lines.add("NO ARTIFACTS CHANGED");
        } else {
          for (var art in wc.artifactsUpdated.take(3)) {
            lines.add("${art.changeType}: ${art.path.split('/').last}");
          }
          if (wc.artifactsUpdated.length > 3) {
            lines.add("+${wc.artifactsUpdated.length - 3} MORE");
          }
        }
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL WHAT CHANGED",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /lab/os/self_heal/what_changed",
    );
  }

  Widget _buildCooldownTransparencyTile() {
    final ct = _snapshot.cooldownTransparency;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!ct.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        status = WarRoomTileStatus.nominal;

        if (ct.entries.isEmpty) {
          lines.add("NO GATING RECORDED");
        } else {
          for (var entry in ct.entries.take(3)) {
            String state = entry.permitted ? "PERMITTED" : "SKIPPED";
            String reason = entry.gateReason;
            if (entry.cooldownRemainingSeconds != null) {
              reason += " (${entry.cooldownRemainingSeconds}s)";
            }
            lines.add("$state: ${entry.actionCode}");
            lines.add("REASON: $reason");
          }
          if (ct.entries.length > 3) {
            lines.add("+${ct.entries.length - 3} MORE");
          }
        }
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL COOLDOWNS",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /lab/os/self_heal/cooldowns",
    );
  }

  Widget _buildRedButtonTile() {
    final rb = _snapshot.redButton;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];
    bool isFounder = AppConfig.isFounderBuild;

    if (!_loading) {
      if (!rb.available) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        status = WarRoomTileStatus.nominal;

        // Capabilities
        if (isFounder) {
          lines.add("FOUNDER ACTIVE");
          if (rb.capabilities.isEmpty) {
            lines.add("NO ACTIONS AVAILABLE");
          } else {
            for (var cap in rb.capabilities) {
              // In a real app, these would be interactive buttons
              // For now, we list them as visible capabilities
              lines.add("[ACTION] $cap");
            }
          }
        } else {
          lines.add("LOCKED (FOUNDER ONLY)");
          lines.add("${rb.capabilities.length} ACTIONS HIDDEN");
        }

        // Last Run
        if (rb.lastRun != null) {
          final lr = rb.lastRun!;
          lines.add("LAST: ${lr.action} (${lr.status})");
        }
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL RED BUTTON",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /lab/os/self_heal/red_button",
    );
  }

  Widget _buildMisfireTier2Tile() {
    final Tier2 = _snapshot.misfireTier2;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!Tier2.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        status = WarRoomTileStatus.nominal;
        if (Tier2.finalOutcome == "FAILED" ||
            Tier2.finalOutcome == "ESCALATED_TO_FOUNDER") {
          status = WarRoomTileStatus.degraded; // Or incident
        }

        lines.add("ID: ${Tier2.incidentId} (${Tier2.finalOutcome})");
        if (Tier2.actionTaken != null) {
          lines.add("ACTION: ${Tier2.actionTaken}");
        }

        // Steps
        if (Tier2.steps.isEmpty) {
          lines.add("NO STEPS RECORDED");
        } else {
          for (var step in Tier2.steps.take(3)) {
            String res = step.result ?? (step.gateReason ?? "PENDING");
            lines.add("${step.stepId}: $res");
          }
          if (Tier2.steps.length > 3) {
            lines.add("+${Tier2.steps.length - 3} MORE STEPS");
          }
        }
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL TIER 2",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: /lab/os/self_heal/misfire/tier2",
    );
  }

  Widget _buildLockReasonTile() {
    final lr = _snapshot.lockReason;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!lr.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        if (lr.lockState == "NONE") {
          status = WarRoomTileStatus.nominal;
          lines.add("NO ACTIVE LOCK");
        } else {
          // LOCKED or DEGRADED
          status = lr.lockState == "LOCKED"
              ? WarRoomTileStatus.incident
              : WarRoomTileStatus.degraded;
          lines.add("STATE: ${lr.lockState}");
          lines.add("CODE: ${lr.reasonCode}");
          lines.add("MODULE: ${lr.module}");
          lines.add("REASON: ${lr.description}");
        }
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL — LOCK REASON",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo:
          "Source: ${lr.isAvailable ? '/lab/os/self_heal/lock_reason' : 'MISSING'}",
    );
  }

  Widget _buildCoverageTile() {
    final c = _snapshot.coverage;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!c.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        status = WarRoomTileStatus.nominal;

        if (c.entries.isEmpty) {
          lines.add("NO DATA AVAILABLE");
        } else {
          // List entries
          // We show top 3-4? Or just list stats?
          // Req: "list of entries: capability, status badge, reason"
          // In a tile we have limited space. We might show a summary count and maybe first few?
          // Or we utilize the scrollable nature if we made it a list.
          // Tile subtitle is List<String>.

          for (var e in c.entries) {
            String badge = "[${e.status.substring(0, 1)}]";
            if (e.status == "AVAILABLE") badge = "[OK]";
            if (e.status == "DEGRADED") badge = "[DEG]";
            if (e.status == "UNAVAILABLE") badge = "[N/A]";

            String line = "$badge ${e.capability}";
            if (e.reason != null && e.reason!.isNotEmpty) {
              line += " (${e.reason})";
            }
            lines.add(line);
          }
        }
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL — COVERAGE",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${c.source}",
    );
  }

  Widget _buildFindingsTile() {
    final f = _snapshot.findings;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> items = [];

    if (!_loading) {
      // f is non-nullable now, defaults to unknown/empty
      // If we want to detect "UNAVAILABLE", we might need a flag in FindingsSnapshot or check if it equals unknown?
      // FindingsSnapshot.unknown has empty findings.
      // If findings empty, we can just say "NO FINDINGS" or "UNAVAILABLE"?
      // But missing file -> unknown -> empty list.
      // Valid empty file -> empty list.
      // We can't distinguish unless separate flag.
      // Ideally we check implicit availability.
      // Let's assume empty list = Nominal (No findings).
      // If it was truly unavailable, we might want a Source check?
      // For now, adhere to D42.08 specific: Read Only List.

      status = WarRoomTileStatus.nominal;
      if (f.findings.isEmpty) {
        items.add("NO FINDINGS");
      } else {
        for (var i = 0; i < f.findings.length && i < 3; i++) {
          final entry = f.findings[i];
          items.add("[${entry.severity}] ${entry.findingCode}");
        }
        if (f.findings.length > 3) {
          items.add("+${f.findings.length - 3} more");
        }
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL — FINDINGS",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: items,
      debugInfo: "Source: /lab/os/self_heal/findings",
    );
  }

  Widget _buildBeforeAfterTile() {
    final diff = _snapshot.beforeAfterDiff;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    Widget? body;

    if (!_loading) {
      if (diff == null) {
        status = WarRoomTileStatus.unavailable;
        // default body will show UNAVAILABLE
      } else {
        status = WarRoomTileStatus.nominal;

        String ts = diff.timestampUtc;
        if (ts.contains("T")) ts = ts.split("T").last.split(".").first;

        body = SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "TIME: $ts",
                style: AppTypography.caption(context)
                    .copyWith(color: AppColors.textPrimary, fontSize: 10),
              ),
              if (diff.operationId != null)
                Text(
                  "OP: ${diff.operationId}",
                  style: AppTypography.caption(context)
                      .copyWith(color: AppColors.textSecondary, fontSize: 9),
                ),
              const SizedBox(height: 4),
              if (diff.changedKeys != null && diff.changedKeys!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    "CHANGED: ${diff.changedKeys!.join(', ')}",
                    style: AppTypography.caption(context).copyWith(
                        color: AppColors.marketBull,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              _buildDiffExpander("BEFORE", diff.beforeState),
              _buildDiffExpander("AFTER", diff.afterState),
            ],
          ),
        );
      }
    }

    return WarRoomTile(
      title: "SELF-HEAL — BEFORE / AFTER",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: const [], // unused if customBody provided (except for loading/unavailable fallback)
      customBody: body,
      debugInfo: "Source: /lab/os/self_heal/before_after",
    );
  }

  Widget _buildDiffExpander(String label, Map<String, dynamic> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Simple pretty print manual or truncated
    final jsonStr = data.toString();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        dense: true,
        title: Text(
          label,
          style: AppTypography.caption(context)
              .copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        children: [
          Text(
            jsonStr,
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              color: AppColors.textSecondary,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildUniverseTile() {
    final u = _snapshot.universe;
    WarRoomTileStatus status = WarRoomTileStatus.loading;
    List<String> lines = [];

    if (!_loading) {
      if (!u.isAvailable) {
        status = WarRoomTileStatus.unavailable;
        lines.add("UNAVAILABLE");
      } else {
        if (u.status == "LIVE" && u.extended == "ON") {
          status = WarRoomTileStatus.nominal;
        } else if (u.status == "SIM") {
          status = WarRoomTileStatus.degraded; // SIM is degraded reality
        } else {
          status = WarRoomTileStatus.degraded; // Partial/Off
        }

        lines.add("CORE: ${u.core}");
        lines.add("EXTENDED: ${u.extended}");
        lines.add("OVERLAY: ${u.overlayState}");

        if (u.overlayAge > 0) {
          lines.add("AGE: ${u.overlayAge}s");
        } else {
          lines.add("AGE: N/A");
        }
      }
    }

    return WarRoomTile(
      title: "UNIVERSE",
      status: _loading ? WarRoomTileStatus.loading : status,
      subtitle: lines,
      debugInfo: "Source: ${u.source}",
    );
  }
}
