import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Using AppTypography
import '../../config/app_config.dart';
import '../../domain/universe/core20_universe.dart';
import '../../repositories/universe_repository.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class UniverseScreen extends StatefulWidget {
  const UniverseScreen({super.key});

  @override
  State<UniverseScreen> createState() => _UniverseScreenState();
}

class _UniverseScreenState extends State<UniverseScreen> {
  late UniverseRepository _repo;
  UniverseSnapshot? _snapshot;
  bool _loading = true;
  final Map<String, DateTime> _lastEliteTriggerTimes = {}; // Session-based cooldown persistence

  @override
  void initState() {
    super.initState();
    _repo = UniverseRepository(api: ApiClient()); // In real app, inject via Provider
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await _repo.fetchUniverse();
    if (mounted) {
      setState(() {
        _snapshot = s;
        _loading = false;
      });
    }
  }

  void _triggerEliteExplain(String reason, String key) {
    // Check cooldown again in case UI is stale
    final last = _lastEliteTriggerTimes[key];
    if (last != null && DateTime.now().difference(last).inMinutes < 30) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Elite Explain on cooldown for this trigger."),
        backgroundColor: AppColors.stateStale,
      ));
      return;
    }

    setState(() {
      _lastEliteTriggerTimes[key] = DateTime.now();
    });

    // Mock Route to Elite Router
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        title: Text("ELITE EXPLAIN ROUTER", style: AppTypography.title(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Key: $key", style: const TextStyle(fontFamily: 'RobotoMono', fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Reason: $reason", style: AppTypography.body(context)),
            const SizedBox(height: 16),
            const Text("[Integrating D43 Elite Arc...]", style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textDisabled)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("CLOSE", style: TextStyle(color: AppColors.accentCyan)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    // Institutional Shell (Managed by MainLayout really, but this is the content)
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text("UNIVERSE", style: AppTypography.title(context)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderSubtle, height: 1.0),
        ),
      ),
      body: _loading 
          ? const Center(child: CircularProgressIndicator()) 
          : _buildContent(context),
    );
  }

  ExtendedSector? _selectedSector;

  Widget _buildContent(BuildContext context) {
    if (_snapshot == null) return const SizedBox.shrink();

    final categories = <String, List<SymbolDefinition>>{};
    for (var def in _snapshot!.coreSymbols) {
      categories.putIfAbsent(def.category, () => []).add(def);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + MediaQuery.of(context).viewPadding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_snapshot != null) _buildIntegrityTile(_snapshot!.integrity),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildCoreTapeSection(_snapshot!.coreTape),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildPulseCoreSection(_snapshot!.pulseCore, _snapshot!.pulseConfidence),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildPulseDriftSection(_snapshot!.pulseDrift),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildSectorSentinelSection(_snapshot!.sectorSentinelRT),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildSentinelHeatmapSection(_snapshot!.sentinelHeatmap),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildGlobalPulseSynthesisSection(_snapshot!.synthesis),
          const SizedBox(height: 8), // Tighter spacing for trigger
          if (_snapshot != null) _buildEliteTrigger(context, _snapshot!),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildFreshnessMonitorSection(_snapshot!.rtFreshness),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildDisagreementReportSection(_snapshot!.disagreementReport),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildGlobalPulseTimelineSection(_snapshot!.pulseTimeline),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildAutoRiskActionsSection(context, _snapshot!.autoRisk),
          const SizedBox(height: 16),
          _buildDegradeRulesSection(),
          const SizedBox(height: 16),
          if (_snapshot != null) _buildWhatChangedSection(_snapshot!.whatChanged),
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 24),
          ...categories.entries.map((e) => _buildCategory(e.key, e.value)),
          _buildExtendedUniverse(),
        ],
      ),
    );
  }

  // ... (header methods skipped, assuming they are unchanged unless I target them)

  // ... (category methods skipped)

  Widget _buildExtendedContent(ExtendedUniverseSnapshot data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.sectors.map(_buildSectorChip).toList(),
        ),
        if (_selectedSector != null)
          _buildBreakdownPanel(_selectedSector!),
      ],
    );
  }

   Widget _buildSectorChip(ExtendedSector sector) {
     final isSelected = _selectedSector == sector;
     return InkWell(
       onTap: () {
         setState(() {
           if (_selectedSector == sector) {
             _selectedSector = null;
           } else {
             _selectedSector = sector;
           }
         });
       },
       borderRadius: BorderRadius.circular(16),
       child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface2 : AppColors.surface1, // Fixed colors
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(
            color: isSelected ? AppColors.accentCyan : AppColors.borderSubtle // Fixed accentPrimary
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sector.name,
              style: AppTypography.label(context).copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary
              ),
            ),
            const SizedBox(width: 6),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
               decoration: BoxDecoration(
                 color: AppColors.bgPrimary,
                 borderRadius: BorderRadius.circular(10),
               ),
               child: Text(
                 "${sector.count}",
                 style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownPanel(ExtendedSector sector) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${sector.name} BREAKDOWN",
            style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (sector.topSymbols.isEmpty)
             Text("No symbols available.", style: AppTypography.caption(context))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sector.topSymbols.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary, // Fixed bgLevel0
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderSubtle)
                ),
                child: Text(s, style: AppTypography.body(context))
              )).toList(),
            )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CORE20 CANON", style: AppTypography.title(context)),
              if (AppConfig.isFounderBuild && (_snapshot?.isFallback ?? false))
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(
                     color: AppColors.stateStale.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(4),
                     border: Border.all(color: AppColors.stateStale.withValues(alpha: 0.3)),
                   ),
                   child: Text("LOCAL_CANON_FALLBACK", 
                     style: AppTypography.caption(context).copyWith(
                       color: AppColors.stateStale, fontSize: 10
                     )
                   ),
                 )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Institutional Reference Set. Non-editable.",
            style: AppTypography.body(context).copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String category, List<SymbolDefinition> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.toUpperCase(),
            style: AppTypography.label(context).copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map(_buildChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExtendedUniverse() {
    final extended = _snapshot?.extended ?? ExtendedUniverseSnapshot.empty;
    final isUnavailable = extended.state == UniverseState.unavailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.borderSubtle, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(
              "EXTENDED UNIVERSE", 
              style: AppTypography.title(context)
            ),
             if (isUnavailable)
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: AppColors.surface1, // Fixed surfaceDisabled
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: AppColors.borderSubtle),
                 ),
                 child: Text("UNAVAILABLE", 
                   style: AppTypography.caption(context).copyWith(
                     color: AppColors.textDisabled
                   )
                 ),
               )
          ],
        ),
        const SizedBox(height: 16),
        if (isUnavailable) 
          Text(
            "Extended universe data access is currently restricted or offline.",
            style: AppTypography.body(context).copyWith(color: AppColors.textSecondary),
          )
        else ...[
          _buildExtendedContent(extended),
          const SizedBox(height: 24),
          _buildGovernanceSection(extended.governance),
          const SizedBox(height: 24),
          _buildOverlaySection(),
          const SizedBox(height: 24),

          _buildSectorHeatmapSection(_snapshot!.sectorHeatmap),
          const SizedBox(height: 24),
          _buildPropagationAuditSection(_snapshot!.propagation), // Verify this call is correct (was buggy earlier)
      ],
      ],
    );
  }

  Widget _buildOverlaySection() {
    final overlay = _snapshot?.overlay ?? OverlayTruthSnapshot.unavailable;
    final isUnavailable = overlay.state == UniverseState.unavailable;

    Color modeColor;
    if (overlay.mode == 'LIVE') {
      modeColor = AppColors.stateLive;
    } else if (overlay.mode == 'SIM') {
      modeColor = AppColors.stateStale; // Orangeish
    } else if (overlay.mode == 'PARTIAL') {
      modeColor = AppColors.stateStale;
    } else {
      modeColor = AppColors.textDisabled;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.borderSubtle, height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text("OVERLAY TRUTH", style: AppTypography.title(context)),
             if (isUnavailable)
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: AppColors.surface2, // Muted background
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: AppColors.borderSubtle), // Grey border
                 ),
                 child: Text("UNAVAILABLE", 
                   style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled)
                 ),
               )
             else
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(
                   color: modeColor.withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                 ),
                 child: Text(overlay.mode, 
                   style: AppTypography.caption(context).copyWith(color: modeColor, fontWeight: FontWeight.bold)
                 ),
               )
          ],
        ),
        
        if (isUnavailable) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stateLocked.withValues(alpha: 0.1), // Red tint
              border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
            ),
            child: Text(
              "Overlay telemetry is not connected.",
              style: AppTypography.body(context).copyWith(color: AppColors.textSecondary),
            ),
          ),
        ] else if (overlay.mode == 'SIM' || overlay.mode == 'PARTIAL' || overlay.freshnessState == 'STALE') ...[
           const SizedBox(height: 16),
           Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stateStale.withValues(alpha: 0.1), // Amber tint
              border: const Border(left: BorderSide(color: AppColors.stateStale, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overlay.mode == 'SIM' ? "SIMULATION MODE ACTIVE" 
                  : (overlay.freshnessState == 'STALE' ? "DATA IS STALE" : "PARTIAL DATA"),
                  style: AppTypography.caption(context).copyWith(color: AppColors.stateStale, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Market intelligence is degraded. Do not trust for execution.",
                  style: AppTypography.body(context).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _buildOverlayRow("Freshness", "${overlay.ageSeconds}s", badge: overlay.freshnessState, badgeColor: overlay.freshnessState == 'OK' ? AppColors.stateLive : AppColors.stateStale),
                const SizedBox(height: 12),
                _buildOverlayRow("Confidence", overlay.confidence, subText: "Integrity & Coverage"),
                const SizedBox(height: 12),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text("Source", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled)),
                     Text(overlay.source, style: AppTypography.caption(context).copyWith(fontFamily: 'RobotoMono', color: AppColors.textDisabled)),
                   ],
                 ),
              ],
            ),
          ),
        ],

        // Founder Debug Hook
        if (AppConfig.isFounderBuild) ...[
           const SizedBox(height: 8),
           Text(
             "Overlay Truth: MODE=${overlay.mode} | AGE=${overlay.ageSeconds}s | CONF=${overlay.confidence}",
             style: const TextStyle(fontSize: 10, fontFamily: 'RobotoMono', color: AppColors.textDisabled),
           ),
        ]
      ],
    );
  } // End _buildOverlaySection

  Widget _buildOverlayRow(String label, String value, {String? badge, Color? badgeColor, String? subText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.body(context).copyWith(color: AppColors.textSecondary)),
            if (subText != null)
              Text(subText, style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
          ],
        ),
        Row(
          children: [
             Text(value, style: AppTypography.body(context).copyWith(fontWeight: FontWeight.bold, fontFamily: 'RobotoMono')),
             if (badge != null) ...[
               const SizedBox(width: 8),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: (badgeColor ?? AppColors.textSecondary).withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: (badgeColor ?? AppColors.textSecondary).withValues(alpha: 0.3)),
                 ),
                 child: Text(badge, style: TextStyle(fontSize: 10, color: badgeColor ?? AppColors.textSecondary, fontWeight: FontWeight.bold)),
               )
             ]
          ],
        )
      ],
    );
  }
  
  Widget _buildGovernanceSection(ExtendedGovernanceSnapshot gov) {
    final isPolicyOnly = gov.source == "CANON";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("EXTENDED GOVERNANCE", 
                 style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)
               ),
               if (isPolicyOnly)
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   decoration: BoxDecoration(
                     color: AppColors.stateStale.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(4),
                     border: Border.all(color: AppColors.stateStale.withValues(alpha: 0.3)),
                   ),
                   child: Text("POLICY SURFACE",
                     style: AppTypography.caption(context).copyWith(
                       color: AppColors.stateStale, fontSize: 10
                     )
                   ),
                 )
            ],
          ),
          const SizedBox(height: 12),
          _buildGovRow("Cooldown", "${(gov.cooldownSeconds / 60).round()}m"),
          _buildGovRow("Daily Cap", "${gov.dailyCap}/day"),
          _buildGovRow("Runs Today", gov.runsToday != null ? "${gov.runsToday} / ${gov.dailyCap}" : "UNKNOWN"),
        ],
      ),
    );
  }

  Widget _buildGovRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body(context).copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.body(context).copyWith(
            fontWeight: FontWeight.bold, 
            fontFamily: 'RobotoMono',
            color: valueColor ?? AppColors.textPrimary
          )), 
        ],
      ),
    );
  }




  Widget _buildIntegrityTile(UniverseIntegritySnapshot integrity) {
    Color statusColor;
    if (integrity.overallState == 'NOMINAL') {
      statusColor = AppColors.stateLive;
    } else if (integrity.overallState == 'DEGRADED') {
      statusColor = AppColors.stateStale; // Orange
    } else {
      statusColor = AppColors.stateLocked; // Red for Unavailable/Incident
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("UNIVERSE INTEGRITY", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(integrity.overallState, 
                  style: AppTypography.caption(context).copyWith(color: statusColor, fontWeight: FontWeight.bold)
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          // Core
          _buildIntegrityRow("CORE_UNIVERSE", integrity.coreStatus),
          // Extended
          _buildIntegrityRow("EXTENDED", integrity.extendedStatus),
          // Overlay
          _buildIntegrityRow("OVERLAY", integrity.overlayStatus),
          // Governance
          _buildIntegrityRow("GOVERNANCE", integrity.governanceStatus),
          // Consumers
          _buildIntegrityRow("CONSUMERS", integrity.consumersStatus),
          const Divider(color: AppColors.borderSubtle, height: 16),
           // Freshness
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("FRESHNESS", style: AppTypography.body(context).copyWith(color: AppColors.textSecondary)),
              Row(
                children: [
                  Text("Age: ${integrity.freshnessAgeSeconds ?? 0}s", style: AppTypography.body(context).copyWith(fontFamily: 'RobotoMono', color: AppColors.textSecondary)),
                  const SizedBox(width: 8),
                  Text(integrity.freshnessState, style: AppTypography.body(context).copyWith(fontWeight: FontWeight.bold, color: _getStatusColor(integrity.freshnessState))),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrityRow(String label, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body(context).copyWith(fontSize: 12)),
          Text(status, style: AppTypography.body(context).copyWith(
            fontWeight: FontWeight.bold, 
            fontSize: 12, 
            color: _getStatusColor(status)
          )),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OK':
      case 'NOMINAL':
      case 'LIVE+OK':
      case 'TELEMETRY':
        return AppColors.stateLive;
      case 'DEGRADED':
      case 'STALE':
      case 'POLICY_ONLY':
      case 'POLICY':
        return AppColors.stateStale;
      case 'UNAVAILABLE':
      case 'INCIDENT':
      case 'ISSUES':
        return AppColors.stateLocked;
      case 'UNKNOWN':
      default:
        return AppColors.textDisabled;
    }
  }

  Widget _buildChip(SymbolDefinition def) {
    return Container(
      width: 100, // Fixed institutional width
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            def.displayLabel,
            style: AppTypography.label(context).copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            def.description,
            style: AppTypography.caption(context).copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }



  Widget _buildSectorHeatmapSection(SectorHeatmapSnapshot heatmap) {
    final bool isUnavailable = heatmap.source == "UNAVAILABLE" || heatmap.sectorStates.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_view, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  "SECTOR HEATMAP (DISPERSION)",
                  style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
             if (!isUnavailable)
               Text("SOURCE: ${heatmap.source}", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
          ],
        ),
        const SizedBox(height: 12),

        if (isUnavailable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderSubtle),
            ),
             child: Text(
               "Sector dispersion data is currently unavailable.",
               style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled),
             ),
          )
        else ...[
           Wrap(
             spacing: 8,
             runSpacing: 8,
             children: [
               "XLF", "XLK", "XLE", "XLY", "XLI", "XLP", "XLV", "XLB", "XLU", "XLC"
             ].map((symbol) {
               final state = heatmap.sectorStates[symbol] ?? "UNAVAILABLE";
               Color color;
               switch (state) {
                 case "HIGH": color = AppColors.stateStale; break; // Warning
                 case "NORMAL": color = AppColors.textSecondary; break; // Calm
                 case "LOW": color = AppColors.accentCyan; break; // Stable
                 default: color = AppColors.textDisabled; 
               }
               
               return Container(
                 width: 60,
                 padding: const EdgeInsets.symmetric(vertical: 6),
                 decoration: BoxDecoration(
                   color: AppColors.surface1,
                   borderRadius: BorderRadius.circular(4),
                   border: Border.all(color: color.withValues(alpha: 0.3)),
                 ),
                 child: Column(
                   children: [
                     Text(symbol, style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold)),
                     const SizedBox(height: 2),
                     Container(
                       width: 6, height: 6,
                       decoration: BoxDecoration(
                         color: color,
                         shape: BoxShape.circle,
                       ),
                     )
                   ],
                 ),
               );
             }).toList(),
           ),
           const SizedBox(height: 8),
           Text(
             "Dispersion = how uneven sector moves are. Not a forecast.",
             style: AppTypography.caption(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textDisabled),
           ),
        ]
      ],
    );
  }

  Widget _buildPropagationAuditSection(UniversePropagationAuditSnapshot propagation) {
     final bool isUnavailable = propagation.status == "UNAVAILABLE";
     final Color statusColor = propagation.status == "OK" ? AppColors.stateLive : (propagation.status == "ISSUES" ? AppColors.stateLocked : AppColors.textDisabled);

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Text("PROPAGATION AUDIT", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
             if (!isUnavailable)
               Text("SOURCE: ${propagation.source}", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
           ],
         ),
         const SizedBox(height: 12),
         
         if (isUnavailable)
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: AppColors.stateLocked.withValues(alpha: 0.1), 
               border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
             ),
             child: Text(
               "Propagation audit is currently unavailable.",
               style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold),
             ),
           )
         else
           Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: AppColors.surface1,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: AppColors.borderSubtle),
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     _buildOverlayRow("Status", propagation.status, badgeColor: statusColor),
                     if (propagation.ageSeconds != null)
                       Text("${propagation.ageSeconds}s ago", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled)),
                   ],
                 ),
                 const SizedBox(height: 12),
                 const Divider(height: 1, color: AppColors.borderSubtle),
                 const SizedBox(height: 12),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                     _buildAuditStat("Consumers", "${propagation.consumersTotal ?? '-'}"),
                     _buildAuditStat("Healthy", "${propagation.consumersOk ?? '-'}", valueColor: AppColors.stateLive),
                     _buildAuditStat("Issues", "${propagation.consumersIssues ?? '-'}", valueColor: (propagation.consumersIssues ?? 0) > 0 ? AppColors.stateLocked : AppColors.textPrimary),
                   ],
                 ),
                 if (propagation.issuesSample.isNotEmpty) ...[
                   const SizedBox(height: 12),
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: AppColors.stateLocked.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: Text(
                       "Issues: ${propagation.issuesSample.join(', ')}",
                       style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked),
                     ),
                   ),
                 ]
               ],
             ),
           ),
       ],
     );
  }

  Widget _buildAuditStat(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.body(context).copyWith(fontWeight: FontWeight.bold, color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildCoreTapeSection(CoreUniverseTapeSnapshot tape) {
    final bool isUnavailable = tape.status == "UNAVAILABLE";
    final Color statusColor = tape.status == "LIVE" ? AppColors.stateLive : (tape.status == "STALE" ? AppColors.stateStale : AppColors.stateLocked);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  "CORE UNIVERSE — REALTIME TAPE",
                  style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
             if (!isUnavailable)
               Text("SOURCE: ${tape.source}", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
          ],
        ),
        const SizedBox(height: 12),
        
        if (isUnavailable)
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: AppColors.stateLocked.withValues(alpha: 0.1), 
               border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
             ),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     "REALTIME TAPE UNAVAILABLE",
                     style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold),
                   ),
                    Text(
                     "Waiting for D40 Real-Time Intelligence Engine.",
                     style: AppTypography.body(context).copyWith(color: AppColors.textSecondary),
                   ),
                ]
             )
           )
        else
          Container(
            padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: AppColors.surface1,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: AppColors.borderSubtle),
             ),
             child: Column(
               children: [
                 _buildOverlayRow("Tape Status", tape.status, badgeColor: statusColor),
                 const SizedBox(height: 8),
                 if (tape.freshnessSeconds != null)
                   _buildOverlayRow("Freshness", "${tape.freshnessSeconds}s ago"),
                 const SizedBox(height: 8),
                 _buildOverlayRow("Size Guard", tape.sizeGuard ? "PASS" : "FAIL", badgeColor: tape.sizeGuard ? AppColors.stateLive : AppColors.stateLocked),
                 
                 const SizedBox(height: 12),
                 const Divider(color: AppColors.borderSubtle, height: 1),
                 const SizedBox(height: 8),
                 Text(
                   "Realtime snapshot, not forecast.",
                   style: AppTypography.caption(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textDisabled),
                 ),
               ],
             ),
          ),
      ],
    );
  }

  Widget _buildPulseCoreSection(PulseCoreSnapshot core, PulseConfidenceSnapshot confidence) {
     final bool isUnavailable = core.state == "UNAVAILABLE";
     Color stateColor;
     switch (core.state) {
       case 'RISK_ON': stateColor = AppColors.accentCyan; break;
       case 'RISK_OFF': stateColor = AppColors.textSecondary; break; // Grey
       case 'SHOCK': stateColor = AppColors.stateStale; break; // Amber
       default: stateColor = AppColors.stateLocked;
     }

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Row(
               children: [
                 const Icon(Icons.monitor_heart_outlined, color: AppColors.textSecondary, size: 16),
                 const SizedBox(width: 8),
                 Text(
                   "PULSE — CORE STATE",
                   style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
                 ),
               ],
             ),
             if (!isUnavailable)
               Text("SOURCE: ${core.source}", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
           ],
         ),
         const SizedBox(height: 12),
         
         if (isUnavailable)
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: AppColors.stateLocked.withValues(alpha: 0.1), 
               border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
             ),
             child: Text(
               "PULSE UNAVAILABLE",
               style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold),
             ),
           )
         else ...[
           // Core Pulse State
           Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("System State", style: AppTypography.body(context).copyWith(color: AppColors.textSecondary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stateColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: stateColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(core.state, style: AppTypography.body(context).copyWith(color: stateColor, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderSubtle, height: 1),
                  const SizedBox(height: 12),
                  // Confidence Bands Sub-panel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildConfidenceCol("Confidence", confidence.confidenceBand),
                      _buildConfidenceCol("Stability", confidence.stabilityBand),
                      _buildConfidenceCol("Regime", confidence.volatilityRegime),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Descriptive state. Coverage & integrity indicator. Not a forecast.",
                    style: AppTypography.caption(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textDisabled),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
           ),
         ]
       ],
     );
  }

  Widget _buildConfidenceCol(String label, String value) {
    Color valColor = AppColors.textPrimary;
    if (value == 'UNAVAILABLE') valColor = AppColors.textDisabled;
    // Simple coloring logic can be expanded here if needed safely
    
    return Column(
      children: [
        Text(label, style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }

  Widget _buildPulseDriftSection(PulseDriftSnapshot drift) {
    // Only show if there's any data or if we want to show the unavailable state explicitly
    // Requirement says "Diagnostic only".
    
    // Simplification: Always show section structure, degrade content if unavailable
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
           children: [
             const Icon(Icons.compare_arrows, color: AppColors.textSecondary, size: 16),
             const SizedBox(width: 8),
             Text(
               "PULSE DRIFT",
               style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
             ),
           ],
         ),
         const SizedBox(height: 12),
         Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _buildDriftRow("Pulse vs Core", drift.coreAgreement),
                const SizedBox(height: 8),
                _buildDriftRow("Pulse vs Sentinel", drift.sentinelAgreement),
                const SizedBox(height: 8),
                _buildDriftRow("Pulse vs Overlay", drift.overlayAgreement),
                const SizedBox(height: 12),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 8),
                Text(
                  "Disagreement highlights context divergence, not error.",
                  style: AppTypography.caption(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textDisabled),
                )
              ],
            ),
         ),
      ],
    );
  }

  Widget _buildDriftRow(String label, String agreement) {
    Color color;
    IconData icon;
    if (agreement == 'AGREE') {
      color = AppColors.stateLive;
      icon = Icons.check_circle_outline;
    } else if (agreement == 'DISAGREE') {
      color = AppColors.stateStale; // Warn
      icon = Icons.warning_amber_rounded;
    } else {
      color = AppColors.textDisabled;
      icon = Icons.help_outline;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body(context).copyWith(fontSize: 12)),
        Row(
          children: [
            Text(agreement, style: AppTypography.caption(context).copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: color),
          ],
        )
      ],
    );
  }

  Widget _buildSectorSentinelSection(SectorSentinelSnapshot sentinel) {
    final bool isUnavailable = sentinel.state == "UNAVAILABLE";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  "SECTOR SENTINEL (RT)",
                  style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                if (sentinel.ageSeconds != null)
                   Text("${sentinel.ageSeconds}s ", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
                _buildStatusBadge(sentinel.state),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        
        // Content
        if (isUnavailable)
           Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.stateLocked.withValues(alpha: 0.1),
                border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
              ),
              child: Text("SENTINEL UNAVAILABLE", style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold)),
            )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: AppColors.surface1,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                 if (sentinel.lastIngestUtc != null) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("INGEST: ${sentinel.lastIngestUtc!.toUtc().toString().split('.').first}Z", style: AppTypography.caption(context).copyWith(fontSize: 9, color: AppColors.textDisabled, fontStyle: FontStyle.italic)),
                    ),
                    const SizedBox(height: 8),
                 ],
                 Wrap(
                   spacing: 6,
                   runSpacing: 6,
                   children: sentinel.sectors.map((s) {
                      Color chipColor = AppColors.textDisabled;
                      if (s.status == "OK" || s.status == "ACTIVE") chipColor = AppColors.stateLive;
                      if (s.status == "STALE" || s.status == "DEGRADED") chipColor = AppColors.stateStale;
                      if (s.status == "UNAVAILABLE") chipColor = AppColors.stateLocked;
                      
                      return Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                         decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                         ),
                         child: Text(s.sector, style: AppTypography.caption(context).copyWith(fontSize: 10, color: chipColor, fontWeight: FontWeight.bold)),
                      );
                   }).toList(),
                 ),
                 const SizedBox(height: 8),
                 Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Real-time sector integrity monitor.", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
                 )
              ],
            ),
          )
      ],
    );
  }



  Widget _buildSentinelHeatmapSection(SentinelHeatmapSnapshot heatmap) {
     final bool isUnavailable = heatmap.state == "UNAVAILABLE";
     
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           children: [
             const Icon(Icons.grid_view, color: AppColors.textSecondary, size: 16),
             const SizedBox(width: 8),
             Text("SENTINEL SECTOR HEATMAP", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
           ],
         ),
         const SizedBox(height: 12),
         
         if (isUnavailable)
           Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.stateLocked.withValues(alpha: 0.1),
                border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
              ),
              child: Text("HEATMAP UNAVAILABLE", style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold)),
            )
         else
           Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: AppColors.surface1,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: AppColors.borderSubtle),
             ),
             child: Column(
               children: [
                 GridView.count(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   crossAxisCount: 4, 
                   childAspectRatio: 1.5,
                   mainAxisSpacing: 8,
                   crossAxisSpacing: 8,
                   children: heatmap.cells.map((cell) => _buildHeatmapTile(cell)).toList(),
                 ),
                 const SizedBox(height: 12),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text("Pressure: Color", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textSecondary)),
                     Text("Dispersion: Dot Intensity", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textSecondary)),
                   ],
                 ),
                 const SizedBox(height: 4),
                 Align(
                   alignment: Alignment.centerLeft,
                   child: Text("Directional pressure & dispersion. Not a forecast.", style: AppTypography.caption(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textDisabled)),
                 )
               ],
             ),
           )
       ],
     );
  }

  Widget _buildHeatmapTile(SentinelHeatCell cell) {
    Color pressureColor;
    switch (cell.pressure) {
      case 'UP': pressureColor = AppColors.accentCyan; break;
      case 'DOWN': pressureColor = AppColors.textSecondary; break; 
      case 'FLAT': pressureColor = AppColors.textDisabled; break;
      case 'MIXED': pressureColor = AppColors.textPrimary; break;
      default: pressureColor = AppColors.stateLocked;
    }
    
    Color dispersionColor;
    switch (cell.dispersion) {
      case 'HIGH': dispersionColor = AppColors.stateStale; break; // Amber
      case 'NORMAL': dispersionColor = AppColors.textSecondary; break; // Grey
      case 'LOW': dispersionColor = AppColors.accentCyan; break; // Cyan
      default: dispersionColor = AppColors.textDisabled;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: pressureColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(cell.sector, style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(cell.pressure.isNotEmpty ? cell.pressure.substring(0, 1) : "-", style: AppTypography.caption(context).copyWith(fontSize: 9, color: pressureColor, fontWeight: FontWeight.bold)),
               Container(
                 width: 6, height: 6,
                 decoration: BoxDecoration(
                   color: dispersionColor,
                   shape: BoxShape.circle,
                 ),
               )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGlobalPulseSynthesisSection(GlobalPulseSynthesisSnapshot synthesis) {
    final bool isUnavailable = synthesis.state == "UNAVAILABLE";
    Color stateColor;
    switch (synthesis.state) {
      case 'RISK_ON': stateColor = AppColors.accentCyan; break;
      case 'RISK_OFF': stateColor = AppColors.textSecondary; break;
      case 'SHOCK': stateColor = AppColors.stateLocked; break; // Red
      case 'FRACTURED': stateColor = AppColors.stateStale; break; // Amber
      default: stateColor = AppColors.stateLocked;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  "GLOBAL PULSE SYNTHESIS",
                  style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
             if (synthesis.asOfUtc != null)
               Text("LAST: ${synthesis.asOfUtc!.toUtc().toString().split('.').first}Z", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
          ],
        ),
        const SizedBox(height: 12),

        if (isUnavailable)
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: AppColors.stateLocked.withValues(alpha: 0.1),
               border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
             ),
             child: Text("SYNTHESIS UNAVAILABLE", style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold)),
           )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildOverlayRow("Risk State", synthesis.state, badgeColor: stateColor),
                     if (synthesis.confidenceBand != null)
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(
                           color: AppColors.surface2,
                           borderRadius: BorderRadius.circular(4),
                           border: Border.all(color: AppColors.borderSubtle),
                         ),
                         child: Text("CONF: ${synthesis.confidenceBand}", style: AppTypography.caption(context).copyWith(fontSize: 9, color: AppColors.textSecondary)),
                       )
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 12),
                Text("Drivers:", style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                if (synthesis.drivers.isEmpty)
                   Text("No active drivers.", style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.textDisabled))
                else
                   ...synthesis.drivers.map((d) => Padding(
                     padding: const EdgeInsets.only(bottom: 2),
                     child: Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text("• ", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                         Expanded(child: Text(d, style: AppTypography.body(context).copyWith(fontSize: 12))),
                       ],
                     ),
                   )),
                 const SizedBox(height: 12),
                 Text(
                   "Descriptive synthesis. Not a forecast.",
                   style: AppTypography.caption(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textDisabled),
                 )
              ],
            ),
          )
      ],
    );
  }

  Widget _buildFreshnessMonitorSection(RealTimeFreshnessSnapshot freshness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  "REAL-TIME FRESHNESS MONITOR",
                  style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            _buildStatusBadge(freshness.overall),
          ],
        ),
        const SizedBox(height: 12),
        Container(
           padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _buildFreshnessRow("Core Tape", freshness.coreTapeAgeSeconds),
                const SizedBox(height: 8),
                _buildFreshnessRow("Sentinel", freshness.sentinelAgeSeconds),
                const SizedBox(height: 8),
                _buildFreshnessRow("Overlay", freshness.overlayAgeSeconds),
                const SizedBox(height: 8),
                _buildFreshnessRow("Synthesis", freshness.synthesisAgeSeconds),
              ],
            ),
        ),
      ],
    );
  }

  Widget _buildFreshnessRow(String label, int? ageSeconds) {
    String status = "UNAVAILABLE";
    Color color = AppColors.stateLocked; // Default unavailable

    if (ageSeconds != null) {
      if (ageSeconds < 300) {
        status = "LIVE";
        color = AppColors.stateLive;
      } else {
        status = "STALE";
        color = AppColors.stateStale;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.textSecondary)),
        Row(
          children: [
             if (ageSeconds != null)
               Text("${ageSeconds}s ", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontSize: 10)),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
               decoration: BoxDecoration(
                 color: color.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(4),
                 border: Border.all(color: color.withValues(alpha: 0.3)),
               ),
               child: Text(status, style: AppTypography.caption(context).copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
             )
          ],
        )
      ],
    );
  }

  Widget _buildDisagreementReportSection(DisagreementReportSnapshot report) {
    if (report.status == "UNAVAILABLE" && report.disagreements.isEmpty) return const SizedBox.shrink(); // Hide if empty and unavailable? Logic says explicit strip if unavailable.
    
    // Actually, prompt says: "If missing/malformed -> UNAVAILABLE with explicit strip." "If none: No disagreements reported."
    
    // Color badgeColor = report.status == "LIVE" ? AppColors.stateLive : (report.status == "STALE" ? AppColors.stateStale : AppColors.stateLocked); // Unused

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Row(
               children: [
                 const Icon(Icons.report_problem_outlined, color: AppColors.textSecondary, size: 16),
                 const SizedBox(width: 8),
                 Text("DISAGREEMENT REPORT", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
               ],
             ),
             _buildStatusBadge(report.status),
           ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
          child: report.status == "UNAVAILABLE"
             ? Text("Diagnostic surface unavailable.", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled))
             : (report.disagreements.isEmpty
                 ? Text("No disagreements reported.", style: AppTypography.body(context).copyWith(color: AppColors.textSecondary))
                 : Column(
                     children: [
                       ...report.disagreements.map((d) => Padding(
                         padding: const EdgeInsets.only(bottom: 12),
                         child: Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // Scope Chip
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: AppColors.surface2,
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: Text(d.scope, style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textSecondary)),
                             ),
                             const SizedBox(width: 8),
                             // Severity
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: (d.severity == "HIGH" ? AppColors.stateLocked : (d.severity == "MED" ? AppColors.stateStale : AppColors.textSecondary)).withValues(alpha: 0.1),
                                 borderRadius: BorderRadius.circular(4),
                               ),
                               child: Text(d.severity, style: AppTypography.caption(context).copyWith(fontSize: 10, fontWeight: FontWeight.bold,
                                  color: d.severity == "HIGH" ? AppColors.stateLocked : (d.severity == "MED" ? AppColors.stateStale : AppColors.textSecondary))),
                             ),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(d.message, style: AppTypography.body(context).copyWith(fontSize: 12)),
                             )
                           ],
                         ),
                       )),
                       const SizedBox(height: 8),
                       Align(
                         alignment: Alignment.centerLeft,
                         child: Text("Diagnostic surface. Not a forecast.", style: AppTypography.caption(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textDisabled)),
                       )
                     ],
                   )
             )
        )
      ],
    );
  }

  Widget _buildGlobalPulseTimelineSection(GlobalPulseTimelineSnapshot timeline) {
    bool isUnavailable = timeline.status == "UNAVAILABLE";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Row(
               children: [
                 const Icon(Icons.history, color: AppColors.textSecondary, size: 16),
                 const SizedBox(width: 8),
                 Text("GLOBAL PULSE TIMELINE (LAST 5)", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
               ],
             ),
           ],
        ),
        const SizedBox(height: 12),
        if (isUnavailable)
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: AppColors.stateLocked.withValues(alpha: 0.1),
               border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
             ),
             child: Text("TIMELINE UNAVAILABLE", style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold)),
           )
        else
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
             child: timeline.entries.isEmpty
                ? Text("No timeline entries available.", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled))
                : Column(
                  children: timeline.entries.map((e) {
                     Color stateColor;
                     switch (e.state) {
                       case 'RISK_ON': stateColor = AppColors.accentCyan; break;
                       case 'RISK_OFF': stateColor = AppColors.textSecondary; break;
                       case 'SHOCK': stateColor = AppColors.stateLocked; break;
                       case 'FRACTURED': stateColor = AppColors.stateStale; break;
                       default: stateColor = AppColors.textDisabled;
                     }
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 8.0),
                       child: Row(
                         children: [
                            Text("${e.tsUtc.toUtc().toString().split('.')[0]}Z", style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary, fontSize: 11)),
                            const SizedBox(width: 12),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                               decoration: BoxDecoration(
                                 color: stateColor.withValues(alpha: 0.1),
                                 borderRadius: BorderRadius.circular(4),
                                 border: Border.all(color: stateColor.withValues(alpha: 0.3)),
                               ),
                               child: Text(e.state, style: AppTypography.caption(context).copyWith(color: stateColor, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                            if (e.note != null) ...[
                               const SizedBox(width: 8),
                               Text(" - ${e.note}", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontSize: 11))
                            ]
                         ],
                       ),
                     );
                  }).toList()
                )
          )
      ],
    );
  }

  Widget _buildDegradeRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 16),
             const SizedBox(width: 8),
             Text("REAL-TIME DEGRADE RULES", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
           ],
        ),
        const SizedBox(height: 12),
        Container(
           width: double.infinity,
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               _buildDegradeRuleItem("Sentinel STALE", "Fallback to Extended Summary", "Global Synthesis, Sentinel Heatmap"),
               const SizedBox(height: 12),
               _buildDegradeRuleItem("Core Tape STALE", "Pulse Degraded", "Pulse Core, Confidence Bands"),
               const SizedBox(height: 12),
               _buildDegradeRuleItem("Overlay STALE", "Synthesis Degraded", "Global Pulse Synthesis"),
               const SizedBox(height: 12),
               _buildDegradeRuleItem("Synthesis STALE", "Elite Explain Trigger (if enabled)", "Elite Overlay only"),
               const SizedBox(height: 16),
               Text(
                 "These rules describe how the OS reacts when freshness or integrity degrades.",
                 style: AppTypography.caption(context).copyWith(fontSize: 10, fontStyle: FontStyle.italic, color: AppColors.textDisabled),
               )
             ],
           ),
        ),
      ],
    );
  }

  Widget _buildEliteTrigger(BuildContext context, UniverseSnapshot snapshot) {
    if (snapshot.synthesis.state == "UNAVAILABLE" || snapshot.rtFreshness.overall == "UNAVAILABLE") {
      return const SizedBox.shrink(); // Safe degrade: Silent
    }

    if (snapshot.synthesis.state != "SHOCK" && 
        snapshot.synthesis.state != "FRACTURED" && 
        snapshot.synthesis.state != "RISK_OFF") {
      return const SizedBox.shrink(); // Trigger condition not met
    }

    final key = "EXPLAIN_GLOBAL_STATE_${snapshot.synthesis.state}";
    final last = _lastEliteTriggerTimes[key];
    if (last != null && DateTime.now().difference(last).inMinutes < 30) {
      if (AppConfig.isFounderBuild) {
         // Debug visibility for Cooldown
         return Align(
           alignment: Alignment.centerLeft,
           child: Text(
             "[DEBUG] Elite Trigger Cooldown: $key", 
             style: const TextStyle(fontSize: 9, color: AppColors.textDisabled)
           ),
         );
      }
      return const SizedBox.shrink(); // Cooldown active
    }

    return Center(
      child: GestureDetector(
        onTap: () => _triggerEliteExplain(snapshot.synthesis.state, key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.surface2, AppColors.surface1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
               Icon(Icons.auto_awesome, size: 14, color: AppColors.accentCyan),
               const SizedBox(width: 8),
               Text(
                 "Elite can explain this shift",
                 style: AppTypography.caption(context).copyWith(
                   color: AppColors.textPrimary, 
                   fontWeight: FontWeight.bold
                 ),
               ),
               const SizedBox(width: 4),
               Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textSecondary)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoRiskActionsSection(BuildContext context, AutoRiskActionSnapshot autoRisk) {
    final bool isUnavailable = autoRisk.state == "UNAVAILABLE";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.security, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text("AUTO-RISK ACTIONS (UI)", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        if (isUnavailable)
           Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.stateLocked.withValues(alpha: 0.1),
                border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
              ),
              child: Text("ACTIONS UNAVAILABLE", style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold)),
            )
        else
          Column(
             children: [
               Align(
                 alignment: Alignment.centerLeft,
                 child: Text("Visibility only. No actions are executed here.", 
                   style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled, fontStyle: FontStyle.italic)
                 ),
               ),
               const SizedBox(height: 8),
               ...autoRisk.actions.map((action) {
                 Color statusColor = AppColors.textDisabled;
                 if (action.status == "ACTIVE") statusColor = AppColors.stateLive;
                 if (action.status == "SKIPPED") statusColor = AppColors.stateStale;

                 return Container(
                   margin: const EdgeInsets.only(bottom: 8),
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     color: AppColors.surface1,
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: AppColors.borderSubtle),
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(action.title, style: AppTypography.body(context).copyWith(fontWeight: FontWeight.bold)),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: statusColor.withValues(alpha: 0.1),
                               borderRadius: BorderRadius.circular(4),
                               border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                             ),
                             child: Text(action.status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                           )
                         ],
                       ),
                       const SizedBox(height: 4),
                       Text(action.description, style: AppTypography.body(context).copyWith(fontSize: 12)),
                       const SizedBox(height: 4),
                       Text("Rationale: ${action.rationale}", style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary, fontSize: 11)),
                     ],
                   ),
                 );
               }).toList()
             ],
          )
      ],
    );
  }

  Widget _buildDegradeRuleItem(String trigger, String reaction, String affects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Text(trigger, style: AppTypography.body(context).copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
             const SizedBox(width: 8),
             const Icon(Icons.arrow_forward, size: 10, color: AppColors.textDisabled),
             const SizedBox(width: 8),
             Text(reaction, style: AppTypography.body(context).copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text("Affects: $affects", style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildWhatChangedSection(WhatChangedSnapshot whatChanged) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             const Icon(Icons.bolt, color: AppColors.textSecondary, size: 16),
             const SizedBox(width: 8),
             Text("WHAT CHANGED? (LAST ~60s)", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
           ],
        ),
        const SizedBox(height: 12),
         Container(
           width: double.infinity,
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
           child: whatChanged.status == "UNAVAILABLE"
              ? Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: AppColors.stateLocked.withValues(alpha: 0.1),
                   border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
                 ),
                 child: Text("MONITOR UNAVAILABLE", style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold)),
              ) 
              : (whatChanged.items.isEmpty 
                  ? Text("No material changes detected.", style: AppTypography.body(context).copyWith(color: AppColors.textSecondary))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: whatChanged.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("• ", style: const TextStyle(color: AppColors.accentCyan, fontSize: 12)),
                            Expanded(child: Text(item.message, style: AppTypography.body(context).copyWith(fontSize: 12))),
                          ],
                        ),
                      )).toList(),
                    )
              )
         ),
      ],
     );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status == "LIVE") {
      color = AppColors.stateLive;
    } else if (status == "STALE") {
      color = AppColors.stateStale;
    } else {
      color = AppColors.stateLocked;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status, style: AppTypography.caption(context).copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
