import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../logic/navigation_bus.dart'; // D44.02B
import '../logic/on_demand_intent.dart'; // D44.06
import '../services/api_client.dart'; // D44.05
import '../logic/on_demand_history_store.dart'; // D44.15
import '../ui/components/decryption_ritual_overlay.dart'; // HF22
import '../logic/standard_envelope.dart'; // D44.07
import '../logic/elite_messages.dart'; // D44.13
import '../widgets/on_demand_context_strip.dart'; // D44.12
import '../widgets/time_traveller_chart.dart'; // D47.HF24
import '../widgets/reliability_meter.dart'; // D47.HF25
import '../widgets/intel_card.dart'; // D47.HF26
import '../widgets/tactical_playbook_block.dart'; // D47.HF27
import '../widgets/elite_mentor_bridge_button.dart'; // D47.HF28
import '../widgets/share_modal.dart'; // D47.HF29
import '../logic/recent_dossier_store.dart'; // D47.HF-RECENT
import '../widgets/recent_dossier_rail.dart'; // D47.HF-RECENT
import '../layout/main_layout.dart'; // To find ancestor if needed
import '../logic/elite_access_window_controller.dart'; // D45.07
import '../widgets/elite_interaction_sheet.dart'; // D43.XX

import '../logic/on_demand_tier_resolver.dart'; // D47.HF31

// D47.HF30 Tier Definitions
// Removed local definition in favor of centralized Resolver

enum OnDemandViewState { idle, loading, result, error }

// OnDemandResult replaced by StandardEnvelope (D44.07)

class OnDemandPanel extends StatefulWidget {
  const OnDemandPanel({super.key});

  @override
  State<OnDemandPanel> createState() => _OnDemandPanelState();
}

class _OnDemandPanelState extends State<OnDemandPanel> {
  final TextEditingController _controller = TextEditingController();
  OnDemandViewState _state = OnDemandViewState.idle;
  String? _errorText;
  String? _usageInfo;
  // HF23: Timeframe Control
  String _timeframe = "DAILY"; // DAILY | WEEKLY

  StandardEnvelope? _result;
  StreamSubscription<NavigationEvent>? _navSubscription;
  final OnDemandHistoryStore _historyStore = OnDemandHistoryStore(); // D44.15
  List<OnDemandHistoryItem> _historyItems = [];
  bool _isAnalyzing = false;
  OnDemandTier _currentTier = OnDemandTier.free; // D47.HF31: Default to Free

  // Recent Dossiers
  final RecentDossierStore _recentStore = RecentDossierStore();
  List<RecentDossierEntry> _recentEntries = [];
  bool _loadedFromSnapshot = false;

  @override
  void initState() {
    super.initState();
    _loadRecents();
    _initHistory(); // D44.15
    _navSubscription = NavigationBus().events.listen((event) {
      // D44: Basic String Argument Support
      if (event.tabIndex == 3 && event.arguments is String) {
        final ticker = event.arguments as String;
        _controller.text = ticker;
        _analyze(); // Default Auto-trigger analysis for string
      }

      // D44.06: Intent Object Support (Prefill Only vs Auto-Trigger)
      if (event.tabIndex == 3 && event.arguments is OnDemandIntent) {
        final intent = event.arguments as OnDemandIntent;
        _controller.text = intent.ticker;

        // Reset state to clear any old result or error when coming from watchlist
        if (_state == OnDemandViewState.result ||
            _state == OnDemandViewState.error) {
          _clear();
          _controller.text = intent.ticker; // Clear wipes text, restore it
        }

        if (intent.autoTrigger) {
          _analyze();
        } else {
          // Prefill only - optionally indicate source
          setState(() {
            // We could show a "Requested from Watchlist" ephemeral message or badge here
          });
        }
      }
    });
  }

  Future<void> _loadRecents() async {
    await _recentStore.init();
    setState(() {
      _recentEntries = _recentStore.getRecent();
    });
    // D47.HF31: Check Tier on init for UI state
    _checkTierStatus();
  }

  Future<void> _checkTierStatus() async {
      final tier = await OnDemandTierResolver.resolve();
      if (mounted) {
          setState(() {
              _currentTier = tier;
          });
      }
  }

  Future<void> _initHistory() async {
    await _historyStore.init();
    if (mounted) _refreshHistory();
  }

  void _refreshHistory() {
    setState(() {
      _historyItems = _historyStore.getRecent();
    });
  }

  @override
  void dispose() {
    _navSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  void _analyze() async {
    final input = _controller.text.trim().toUpperCase();
    if (input.isEmpty) return;

    // HF23: 10:30 AM Rule (Manual UTC Offset)
    // Jan 2026 is Standard Time (UTC-5)
    // 09:30 ET = 14:30 UTC. 10:30 ET = 15:30 UTC.
    // Spec: "From 09:30 to 10:30 ET" if DAILY.
    bool locked = false;
    final nowUtc = DateTime.now().toUtc();
    // Convert to ET (Manual -5)
    final nowEt = nowUtc.subtract(const Duration(hours: 5));

    // Check range: 09:30 <= now < 10:30
    final startLock = DateTime(nowEt.year, nowEt.month, nowEt.day, 9, 30);
    final endLock = DateTime(nowEt.year, nowEt.month, nowEt.day, 10, 30);

    if (_timeframe == "DAILY" && nowEt.isAfter(startLock) && nowEt.isBefore(endLock)) {
      locked = true;
    }
    // Also logic: "After 10:30 ET: UNLOCKED". Before 09:30? Usually pre-market.
    // Spec says "From 09:30 to 10:30 ET: display LOCKED". Implicitly others OK.

    if (locked) {
      // Just show banner? Or force state?
      // Spec: "Force 'projection locked' mode for forward-looking visuals... Still allow showing past/now".
      // The API might return projection anyway.
      // We will just show the banner for now as the 'projection locked' visuals are part of the result rendering (HF24).
      // For HF23, we simply identify the state.
    }

    // 1. Validate Pattern Only (Global Universe)
    final validTicker = RegExp(r'^[A-Z0-9._-]{1,12}$');
    if (!validTicker.hasMatch(input)) {
      setState(() {
        _errorText = "Invalid Ticker Format. Use symbols like AAPL, BTC-USD.";
      });
      return;
    }

    // 2. Set Loading
    setState(() {
      _state = OnDemandViewState.loading;
      _errorText = null;
      _isAnalyzing = true; // Set analyzing state
      _loadedFromSnapshot = false; // Clear snapshot flag
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    });

    // 3. Real Fetch (D44.05) wrapped in Ritual (HF22)
    final api = context.findAncestorWidgetOfExactType<MainLayout>() != null
        ? ApiClient()
        : ApiClient();

    final response = await DecryptionRitualOverlay.run(context, task: api.fetchOnDemandContext(input, timeframe: _timeframe));

    if (!mounted) return;

    // HF22 Safety: If response is null (Timeout/Cancellation), treat as error
    if (response == null) {
      setState(() {
        _state = OnDemandViewState.error;
        _errorText = "Signal lost during decryption.";
        _isAnalyzing = false;
      });
      return;
    }

    // 4. Handle Result
    setState(() {
      if (response["status"] == "BLOCKED") {
        _state = OnDemandViewState.error;
        final reason = response["reason"] ?? "LIMIT_REACHED";
        final cooldown = response["cooldown_remaining"] ?? 0;

        if (reason == "TIER_LOCKED") {
          _errorText = "Feature Locked for this Tier. Upgrade required.";
        } else if (reason == "COOLDOWN_ACTIVE") {
          _errorText = "Cooling down... Wait $cooldown seconds.";
        } else {
          _errorText = "Daily Limit Reached (Resets 04:00 ET)";
        }

        final usage = response["usage"] ?? 0;
        final limit = response["limit"] ?? 0;
        final tier = response["tier"] ?? "UNKNOWN";
        if (limit == -1) {
          _usageInfo = "$tier: Unlimited";
        } else {
          _usageInfo = "$tier: $usage/$limit Today";
        }
        _isAnalyzing = false;
        return;
      }

      // Update Usage from Meta
      if (response.containsKey("_meta")) {
        final meta = response["_meta"];
        final tier = meta["tier"];
        final usage = meta["usage"];
        final limit = meta["limit"];
        if (limit == -1) {
          _usageInfo = "$tier: Unlimited";
        } else {
          _usageInfo = "$tier: $usage/$limit Today";
        }
      }

      _state = OnDemandViewState.result;

      // D44.07: Standard Envelope & Lexicon Guard
      final rawEnvelope = EnvelopeBuilder.build(response);
      final safeEnvelope = LexiconSanitizer.apply(rawEnvelope);

      _result = safeEnvelope;
      _isAnalyzing = false;
      _loadedFromSnapshot = false; // Fresh run
    });

    // D44.15: Record Record Success
    await _historyStore.record(ticker: input);
    if (mounted) _refreshHistory();

    // HF-RECENT: Save Snapshot on Success
    if (_result != null && (_result!.status == EnvelopeStatus.live || _result!.status == EnvelopeStatus.stale)) { // Save invalidates too? Let's save anything that produced a result.
      await _recentStore.record(
          ticker: input,
          timeframe: _timeframe,
          asOfUtc: _result!.asOfUtc.toIso8601String(),
          reliabilityState: _deriveReliabilityState(_result!), // Helper needed or parse payload? helper exists from ReliabilityMeter logic but it's buried in build.
          // We'll parse the reliability state from the envelope or re-derive securely.
          // Actually, ReliabilityMeter logic is view-only. Let's peek at payload 'state'.
          rawPayload: _result!.rawPayload
      );
      await _loadRecents(); // Refresh UI
    }
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _state = OnDemandViewState.idle;
      _result = null;
      _errorText = null;
      _isAnalyzing = false;
      _loadedFromSnapshot = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Layout Police: Uses Safe Scroll + Padding
    final bottomPadding = 100 + MediaQuery.of(context).viewPadding.bottom;

    return Container(
      color: Colors.transparent, // Handled by MainLayout
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: bottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ---
            Text(
              "ON-DEMAND",
              style: AppTypography.headline(context)
                  .copyWith(fontSize: 24, letterSpacing: 1.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Instant context snapshot",
              style: AppTypography.body(context)
                  .copyWith(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),

            // HF23: Timeframe Selector
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeframeTab("DAILY", AppColors.neonCyan),
                const SizedBox(width: 12),
                _buildTimeframeTab("WEEKLY", AppColors.stateStale), // Gold
              ],
            ),

            // HF23: 10:30 AM Lock Banner
            ..._buildLockBannerIfNeeded(),

            if (_usageInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                _usageInfo!,
                style: AppTypography.label(context)
                    .copyWith(color: AppColors.accentCyanDim, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // --- HISTORY (D44.15) ---
            if (_historyItems.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _historyItems.map((item) {
                  return ActionChip(
                    label:
                    Text(item.ticker, style: AppTypography.label(context)),
                    backgroundColor: AppColors.surface2,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    onPressed: () {
                      // Prefill (No Auto-Trigger)
                      _controller.text = item.ticker;
                      FocusScope.of(context)
                          .requestFocus(); // Better UX, let them hit enter or Analyze
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // --- INPUT ---
            TextField(
              controller: _controller,
              style: AppTypography.headline(context).copyWith(fontSize: 20),
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
              decoration: InputDecoration(
                hintText: "e.g., AAPL",
                hintStyle: TextStyle(
                    color: AppColors.textDisabled.withValues(alpha: 0.5)),
                filled: true,
                fillColor: AppColors.surface1,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.neonCyan),
                ),
                counterText: "",
              ),
              onChanged: _onChanged,
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: AppTypography.body(context)
                    .copyWith(color: AppColors.stateLocked, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),

            // --- ACTIONS ---
            Row(
              children: [
                if (_state != OnDemandViewState.idle)
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      onPressed: _clear,
                      child: Text("CLEAR",
                          style: AppTypography.label(context)
                              .copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed:
                    _state == OnDemandViewState.loading ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonCyan,
                      foregroundColor: AppColors.bgPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      disabledBackgroundColor: AppColors.surface2,
                    ),
                    child: _state == OnDemandViewState.loading
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textPrimary))
                        : Text("ANALYZE NOW",
                        style: AppTypography.label(context).copyWith(
                            color: AppColors.bgPrimary,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // --- RESULTS CONTAINER ---
            _buildResultContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContainer() {
    switch (_state) {
      case OnDemandViewState.idle:
        return Center(
          child: Column(
            children: [
              Icon(Icons.flash_on,
                  size: 48,
                  color: AppColors.textDisabled.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                "Awaiting request...",
                style: AppTypography.body(context)
                    .copyWith(color: AppColors.textDisabled),
              ),
            ],
          ),
        );

      case OnDemandViewState.loading:
        return const Center(
          child: Column(
            children: [
              SizedBox(height: 24),
              CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.neonCyan),
              SizedBox(height: 16),
              Text("Analyzing Global Market Data...",
                  style: TextStyle(color: AppColors.neonCyan)),
            ],
          ),
        );

      case OnDemandViewState.result:
      case OnDemandViewState.error:
        if (_result == null) return const SizedBox.shrink();

        // D44.16 Stale Warning Logic
        bool isStale = _result!.status == EnvelopeStatus.stale;
        if (!isStale) {
          final ageMinutes =
              DateTime.now().difference(_result!.asOfUtc).inMinutes;
          if (ageMinutes > 60) isStale = true;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            children: [
              if (isStale) ...[
                _buildStaleWarning(),
                const SizedBox(height: 16),
              ],
              
              // HF32: Cost Policy Banner
              if (_result!.rawPayload['policy_block'] == true) ...[
                   Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.accentCyanDim)
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              const Icon(Icons.history, size: 16, color: AppColors.accentCyanDim),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "Already generated today. Showing latest cached dossier.",
                                  style: AppTypography.caption(context).copyWith(color: AppColors.accentCyanDim),
                                  textAlign: TextAlign.center,
                                ),
                              )
                          ]
                      )
                   ),
              ],

              // HF-RECENT: Recent Dossier Rail
              if (!_isAnalyzing && _recentEntries.isNotEmpty) ...[
                RecentDossierRail(
                    entries: _recentEntries,
                    onTap: _loadFromSnapshot
                ),
                const SizedBox(height: 16),
              ],

              // D44.11 Header
              EnvelopePreviewHeader(
                  envelope: _result!, ticker: _controller.text.toUpperCase()),

              // D44.12 Context Strip & Share (HF29)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Expanded(
                            child: OnDemandContextStrip(
                                envelope: _result!, ticker: _controller.text.toUpperCase()),
                        ),
                        IconButton(
                            icon: const Icon(Icons.share, size: 18, color: AppColors.neonCyan),
                            onPressed: _openShareModal,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Share Insight",
                        ),
                    ],
                ),
              ),
              if (_loadedFromSnapshot)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      "LOADED FROM LOCAL SNAPSHOT",
                      style: AppTypography.caption(context).copyWith(
                          color: AppColors.stateStale,
                          fontStyle: FontStyle.italic
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              // D47.HF24: Time-Traveller Chart
              // HF30: Blur Future if FREE. PLUS/ELITE see clearly.
              _buildTimeTravellerChart(blurFuture: _currentTier == OnDemandTier.free),

              const SizedBox(height: 12),
              // D47.HF25: Reliability Meter
              _buildReliabilityMeter(),

              const SizedBox(height: 16),
              // D47.HF26: Intel Cards (Micro-Briefings)
              ..._buildIntelInterface(),

              const SizedBox(height: 16),
              // D47.HF27: Tactical Playbook
              // HF30: Blur Tactical if FREE. PLUS/ELITE see clearly.
              _buildTacticalPlaybook(isBlurred: _currentTier == OnDemandTier.free),

              const SizedBox(height: 16),
              // D47.HF28: Elite Mentor Bridge
              // HF30: Only Elite sends messages. PLUS/FREE locked.
              EliteMentorBridgeButton(
                  isLocked: _currentTier != OnDemandTier.elite,
                  onTap: _openMentorBridge
              ),

              const Divider(color: AppColors.borderSubtle, height: 24),

              if (_result!.sanitized) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "[SANITIZED] Content flagged by Lexicon Guard",
                    style: AppTypography.label(context)
                        .copyWith(color: AppColors.stateLocked),
                  ),
                ),
              ],

              ..._result!.bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ",
                        style: TextStyle(color: AppColors.neonCyan)),
                    Expanded(
                        child: Text(b, style: AppTypography.body(context))),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              // Footer timestamp removed in D44.11 (Moved to Header)

              // HF21: Provabilistic Context
              if (_result!.rawPayload.containsKey("projection")) ...[
                const Divider(color: AppColors.borderSubtle, height: 24),
                _buildProbabilisticContext(context, _result!.rawPayload["projection"]),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildProbabilisticContext(BuildContext context, Map<String, dynamic> proj) {
    final state = proj["state"] ?? "UNKNOWN";
    final scenarios = proj["scenarios"] ?? {};
    final inputs = proj["inputs"] ?? {};
    final missing = proj["missingInputs"] ?? [];

    Color stateColor = AppColors.textDisabled;
    if (state == "OK") stateColor = AppColors.stateLive;
    if (state == "CALIBRATING") stateColor = AppColors.stateStale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("PROBABILISTIC CONTEXT",
                style: AppTypography.label(context).copyWith(color: AppColors.textSecondary, letterSpacing: 1.1)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: stateColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: stateColor.withValues(alpha: 0.3)),
              ),
              child: Text(state,
                  style: AppTypography.label(context).copyWith(color: stateColor, fontSize: 10)),
            )
          ],
        ),
        const SizedBox(height: 12),

        // Scenarios
        if (scenarios.containsKey("base"))
          _buildScenarioRow(context, "BASE", scenarios["base"]),
        const SizedBox(height: 8),
        if (scenarios.containsKey("stress"))
          _buildScenarioRow(context, "STRESS", scenarios["stress"]),

        const SizedBox(height: 16),

        // Inputs Chips
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var k in inputs.keys)
              _buildInputChip(context, k, inputs[k]["status"], missing.contains(k)),
          ],
        )
      ],
    );
  }

  Widget _buildScenarioRow(BuildContext context, String label, Map<String, dynamic> data) {
    final notes = (data["notes"] as List?)?.map((e) => e.toString()).toList() ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label(context).copyWith(color: AppColors.textDisabled, fontSize: 10)),
        ...notes.map((n) => Text("• $n", style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.textPrimary))),
      ],
    );
  }

  Widget _buildInputChip(BuildContext context, String label, String status, bool isMissing) {
    Color color = AppColors.textDisabled;
    if (status == "LIVE" || status == "AVAILABLE") color = AppColors.accentCyanDim;
    if (isMissing) color = AppColors.stateLocked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text("$label: $status", style: TextStyle(color: color, fontSize: 9)),
    );
  }

  Widget _buildStaleWarning() {
    final ts = _result!.asOfUtc.toUtc();
    final timeStr =
        "${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')} UTC";

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.stateStale.withValues(alpha: 0.1),
          border:
          Border.all(color: AppColors.stateStale.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 16, color: AppColors.stateStale),
            const SizedBox(width: 8),
            Text("As of $timeStr · Stale",
                style: AppTypography.label(context)
                    .copyWith(color: AppColors.stateStale)),
          ],
        ));
  }

  // HF23: UI Helpers

  Widget _buildTimeframeTab(String label, Color accentColor) {
    final isSelected = _timeframe == label;
    return GestureDetector(
      onTap: () {
        if (_state == OnDemandViewState.loading) return; // Block while loading
        setState(() {
          _timeframe = label;
        });
        // Auto-refresh if we have a valid ticker and not idle/error?
        // Spec: "When selector changes, refetch".
        if (_controller.text.isNotEmpty) {
          _analyze();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
              color: isSelected ? accentColor : AppColors.borderSubtle,
              width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: AppTypography.label(context).copyWith(
                color: isSelected ? accentColor : AppColors.textDisabled,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  bool _isDailyLocked() {
    // Recalculate lock state for UI render (reactive)
    final nowUtc = DateTime.now().toUtc();
    final nowEt = nowUtc.subtract(const Duration(hours: 5));
    final startLock = DateTime(nowEt.year, nowEt.month, nowEt.day, 9, 30);
    final endLock = DateTime(nowEt.year, nowEt.month, nowEt.day, 10, 30);

    return (_timeframe == "DAILY" &&
        nowEt.isAfter(startLock) &&
        nowEt.isBefore(endLock));
  }

  List<Widget> _buildLockBannerIfNeeded() {
    if (!_isDailyLocked()) return [];

    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.stateLocked.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.stateLocked),
            borderRadius: BorderRadius.circular(4)),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.stateLocked, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
                    "INITIAL BALANCE FORMING. AI CALIBRATION IN PROGRESS.",
                    style: AppTypography.caption(context).copyWith(
                        color: AppColors.stateLocked,
                        fontWeight: FontWeight.bold)))
          ],
        ),
      )
    ];
  }

  Widget _buildTimeTravellerChart({required bool blurFuture}) {
    // Extract series from rawPayload if available.
    // Expected structure: result.rawPayload['series'] -> { 'past': [...], 'future': [...] }
    List<ChartCandle> past = [];
    List<ChartCandle> future = [];
    bool isCalibrating = true;

    if (_result != null && _result!.rawPayload.containsKey('series')) {
      final series = _result!.rawPayload['series'];
      if (series is Map) {
        if (series['past'] is List) {
          past = (series['past'] as List).map((e) => ChartCandle.fromJson(e)).toList();
        }
        if (series['future'] is List) {
          future = (series['future'] as List).map((e) => ChartCandle.fromJson(e)).toList();
        }
        isCalibrating = false; // We have data
      }
    }

    return TimeTravellerChart(
      pastCandles: past,
      futureCandles: future,
      isLocked: _isDailyLocked(),
      isCalibrating: isCalibrating,
      height: 200,
      blurFuture: blurFuture, // HF30: Gated Logic
    );
  }

  // D47.HF27: Tactical Playbook
  Widget _buildTacticalPlaybook() {
    if (_result == null) return const SizedBox.shrink();
    if (_result!.watchBullets.isEmpty && _result!.invalidateBullets.isEmpty) return const SizedBox.shrink();

    return TacticalPlaybookBlock(
      watchItems: _result!.watchBullets,
      invalidateItems: _result!.invalidateBullets,
      isCalibrationMode: _timeframe == "INTRADAY",
      isBlurred: _resolveTier() != OnDemandTier.elite, // HF30: Gate Tactics
    );
  }

  Widget _buildReliabilityMeter() {
    if (_result == null) return const SizedBox.shrink();

    // 1. Inputs Logic
    // Total 4: Options, News, Macro, Evidence
    int totalInputs = 4;
    int missingCount = 0;
    if (_result!.rawPayload.containsKey('missingInputs')) {
      final missing = _result!.rawPayload['missingInputs'];
      if (missing is List) missingCount = missing.length;
    }
    int activeInputs = totalInputs - missingCount;
    if (activeInputs < 0) activeInputs = 0;

    // 2. Sample Size Logic
    int? sampleSize;
    if (_result!.rawPayload.containsKey('inputs') &&
        _result!.rawPayload['inputs'] is Map &&
        _result!.rawPayload['inputs'].containsKey('evidence')) {

      final ev = _result!.rawPayload['inputs']['evidence'];
      if (ev is Map && ev.containsKey('sample_size')) {
        sampleSize = ev['sample_size'];
      }
    }

    // 3. State Logic
    String state = "CALIBRATING";

    // Priority 1: Market Lock
    if (_isDailyLocked()) {
      state = "CALIBRATING";
    }
    // Priority 2: Backend State
    else if (_result!.rawPayload.containsKey('state')) {
      final backendState = _result!.rawPayload['state'];

      if (backendState == "OK") {
        // Refine OK based on Samples
        if (sampleSize != null) {
          if (sampleSize > 30) {
            state = "HIGH";
          } else if (sampleSize > 10) {
            state = "MED";
          } else {
            state = "LOW";
          }
        } else {
          state = "MED"; // OK but no samples?
        }
      } else if (backendState == "INSUFFICIENT_DATA") {
        state = "LOW";
      } else if (backendState == "PROVIDER_DENIED") {
        state = "LOW";
      } else {
        state = "CALIBRATING";
      }
    }

    return ReliabilityMeter(
        state: state,
        sampleSize: sampleSize,
        driftState: "N/A", // Not yet in payload
        activeInputs: activeInputs,
        totalInputs: totalInputs
    );
  }

  List<Widget> _buildIntelInterface() {
    if (_result == null) return [];

    List<Widget> cards = [];

    // --- CARD 1: EVIDENCE (PROBABILITY) ---
    // Extract: inputs.evidence.metrics['win_rate'], ['avg_return']
    // Fallback: CALIBRATING
    List<String> evidenceLines = [];
    bool evidenceCalibrating = true;
    Color evidenceAccent = AppColors.neonCyan; // Default calibrating

    if (_result!.rawPayload.containsKey('inputs') &&
        _result!.rawPayload['inputs'] is Map) {

      final inputs = _result!.rawPayload['inputs'];
      if (inputs.containsKey('evidence') && inputs['evidence'] is Map) {
        final ev = inputs['evidence'];
        if (ev.containsKey('metrics') && ev['metrics'] is Map) {
          final m = ev['metrics'];

          if (m.containsKey('win_rate')) {
            evidenceLines.add("Historical Match: ${(m['win_rate'] * 100).toStringAsFixed(0)}%");
            evidenceCalibrating = false;
            // Color logic: > 60 Green, < 40 Red, else Amber
            if (m['win_rate'] > 0.6) {
              evidenceAccent = AppColors.marketBull;
            } else if (m['win_rate'] < 0.4) {
              evidenceAccent = AppColors.marketBear;
            } else {
              evidenceAccent = AppColors.stateStale; // Amber
            }
          }

          if (m.containsKey('avg_return')) {
            final ret = m['avg_return'];
            final sign = ret >= 0 ? "+" : "";
            evidenceLines.add("Avg Move: $sign${(ret * 100).toStringAsFixed(2)}%");
          }
        }
      }
    }

    if (evidenceCalibrating) {
      evidenceLines.add("Insufficient historical matches.");
    }

    cards.add(IntelCard(
      title: "PROBABILITY ENGINE",
      icon: Icons.query_stats,
      lines: evidenceLines,
      accentColor: evidenceAccent,
      tooltip: "Chronos Evidence Engine (Historical Matching)",
      isCalibrating: evidenceCalibrating,
    ));


    // --- CARD 2: CATALYST RADAR (NEWS) ---
    // Extract: inputs.news.headlines (List)
    // Fallback: OFFLINE
    List<String> newsLines = [];
    bool newsOffline = true;
    Color newsAccent = AppColors.textDisabled;

    if (_result!.rawPayload.containsKey('inputs') &&
        _result!.rawPayload['inputs'] is Map) {

      final inputs = _result!.rawPayload['inputs'];
      if (inputs.containsKey('news') && inputs['news'] is Map) {
        final news = inputs['news'];
        if (news.containsKey('headlines') && news['headlines'] is List) {
          final rawHeadlines = news['headlines'] as List;
          if (rawHeadlines.isNotEmpty) {
            newsLines = rawHeadlines.take(2).map((e) => e.toString()).toList();
            newsOffline = false;
            newsAccent = AppColors.neonCyan; // Active
          }
        }
      }
    }

    if (newsOffline) {
      newsLines.add("Radar OFFLINE. (Sources: 0)");
    }

    cards.add(IntelCard(
      title: "CATALYST RADAR",
      icon: Icons.radar,
      lines: newsLines,
      accentColor: newsAccent,
      tooltip: "News Engine (Headlines & Event Clusters)",
      isCalibrating: false, // Explicit offline text used instead
    ));


    // --- CARD 3: REGIME & STRUCTURE ---
    // Extract: contextTags.macro (List) or scenario notes?
    // Let's use scenario notes for structure if macro is stub.
    // Or just simple Macro status.
    List<String> macroLines = [];
    Color macroAccent = AppColors.textDisabled;

    // Check Macro Status
    String macroStatus = "NEUTRAL";
    if (_result!.rawPayload.containsKey('contextTags') &&
        _result!.rawPayload['contextTags'] is Map) {
      final tags = _result!.rawPayload['contextTags'];
      if (tags.containsKey('macro') && tags['macro'] is Map) {
        // Parse tags?
        // "MACRO_STUB_NEUTRAL"
        final mTags = tags['macro']['tags'];
        if (mTags is List && mTags.contains('MACRO_STUB_NEUTRAL')) {
          macroStatus = "NEUTRAL (STUB)";
        }
      }
    }
    macroLines.add("Macro Environment: $macroStatus");
    macroLines.add("Market Structure: BALANCED"); // Hardcoded confident default for V1

    cards.add(IntelCard(
      title: "REGIME & STRUCTURE",
      icon: Icons.account_balance,
      lines: macroLines,
      accentColor: macroAccent, // Neutral
      tooltip: "Macro & Structural Context",
      isCalibrating: false,
    ));

    return cards;
  }

  Widget _buildTacticalPlaybook() {
    if (_result == null) return const SizedBox.shrink();

    List<String> watch = [];
    List<String> invalidate = [];
    bool isCalibrationMode = false;

    // 1. Check Lock (Override)
    if (_isDailyLocked()) {
      isCalibrationMode = true;
      watch = [
        "Initial balance forming; wait for structure confirmation.",
        "Volume profile development vs overnight range."
      ];
    bool isCalibrating = true;

    if (_result != null && _result!.rawPayload.containsKey('tactical')) {
      final tac = _result!.rawPayload['tactical'];
      if (tac is Map) {
        if (tac['watch'] is List) {
          watch = (tac['watch'] as List).map((e) => e.toString()).toList();
        }
        if (tac['invalidate'] is List) {
          invalidate = (tac['invalidate'] as List).map((e) => e.toString()).toList();
        }
        isCalibrating = false;
      }
    }

    // Fallback if empty
    if (watch.isEmpty) watch = ["Calibration in progress..."];
    if (invalidate.isEmpty) invalidate = ["--"];

    return TacticalPlaybookBlock(
      watchItems: watch,
      invalidateItems: invalidate,
      isCalibrationMode: isCalibrating,
      isBlurred: isBlurred, // HF30: Gated Logic
    );
  }

  // Helper to re-derive reliability state string for storage
  String _deriveReliabilityState(StandardEnvelope env) {
    if (env.rawPayload.containsKey('state')) {
      final s = env.rawPayload['state'];
      if (s == "OK") {
        // We could check sample size but for the snippet "HIGH/MED" is fine.
        // Let's simple-map or dig deeper.
        // Only reliable way is to replicate the logic or store what was rendered.
        // For now, let's trust "OK" -> "MED" (Default) unless sample size tells us more.
        // Or better, check the payload input.
        if (env.rawPayload['inputs']?['evidence']?['status'] == "LIVE") return "HIGH"; // Approximation
        return "MED";
      }
      if (s == "CALIBRATING") return "CALIBRATING";
      if (s == "INSUFFICIENT_DATA") return "LOW";
    }
    return "N/A";
  }

  void _loadFromSnapshot(RecentDossierEntry entry) {
    // Load raw payload into Envelope
    final env = EnvelopeBuilder.build(entry.rawPayload);

    setState(() {
      _controller.text = entry.ticker;
      // Set View based on timeframe string
      _timeframe = entry.timeframe; // Use the timeframe from the snapshot
      _state = OnDemandViewState.result; // Assume result state
      _result = env;
      _loadedFromSnapshot = true;
      _errorText = null; // Clear any previous errors
      _isAnalyzing = false; // Not actively analyzing
    });
  }
  
  void _openMentorBridge() {
      if (!_isEliteUnlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Elite unlocks institutional mentoring on every dossier."),
                  backgroundColor: AppColors.surface2,
                  duration: Duration(seconds: 3),
              )
          );
          return;
      }
      
      final payload = _buildContextPayload();
      
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => EliteInteractionSheet(
              initialExplainKey: 'EXPLAIN_ON_DEMAND_RESULT',
              initialPayload: payload,
          )
      );
  }
  
  Map<String, dynamic> _buildContextPayload() {
      if (_result == null) return {};
      
      return {
          'ticker': _controller.text.toUpperCase(),
          'timeframe': _timeframe,
          'status': _result!.status.toString().split('.').last.toUpperCase(),
          'source': _result!.source.toString().split('.').last.toUpperCase(),
          'timestamp': _result!.asOfUtc.toIso8601String(),
          'badges': _result!.confidenceBadges.map((e) => e.toString().split('.').last.toUpperCase()).toList(),
          'reliability': _deriveReliabilityState(_result!), // Re-use helper
          // Add bullets for context?
          'top_bullet': _result!.bullets.isNotEmpty ? _result!.bullets.first : "N/A",
          // Add raw summary?
          'summary_bullets': _result!.bullets,
          // Extract tactical if present?
          // We pass raw payload subsets if needed, but let's keep it clean.
      };
  }

  // D47.HF30: Tier Resolution
  // Currently binary (Free vs Elite) based on _isEliteUnlocked.
  // Plus awareness ready but defaulted to Free for now.
  // D47.HF31: Legacy _resolveTier removed. Use _currentTier.

  void _openShareModal() {
      if (_result == null) return;
      
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ShareModal(
              ticker: _controller.text.toUpperCase(),
              timeframe: _timeframe,
              reliability: _deriveReliabilityState(_result!),
              topBullet: _result!.bullets.isNotEmpty ? _result!.bullets.first : "N/A",
              // HF31: Viral Safety. Share modal creates Mini-Card.
              // Mini-Card (checked in verification) has "Blurred Lines" hardcoded.
              // So no extra flag needed here if MiniCardWidget always blurs.
          )
      );
  }
}


class EnvelopePreviewHeader extends StatelessWidget {
  final StandardEnvelope envelope;
  final String ticker;

  const EnvelopePreviewHeader(
      {super.key, required this.envelope, required this.ticker});

  @override
  Widget build(BuildContext context) {
    // 1. Status Chip Color
    Color statusColor;
    switch (envelope.status) {
      case EnvelopeStatus.live:
        statusColor = AppColors.stateLive;
        break;
      case EnvelopeStatus.stale:
        statusColor = AppColors.stateStale;
        break;
      case EnvelopeStatus.locked:
        statusColor = AppColors.stateLocked;
        break;
      case EnvelopeStatus.unavailable:
        statusColor = AppColors.textDisabled;
        break;
      case EnvelopeStatus.error:
        statusColor = AppColors.stateLocked;
        break;
    }

    // 2. Format Timestamp
    final dt = envelope.asOfUtc.toUtc();
    final timeStr =
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} UTC";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Row: Status | Source | Timestamp
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            // Left: Chips
            Wrap(
              spacing: 6,
              children: [
                _buildChip(
                    context, envelope.status.name.toUpperCase(), statusColor),
                _buildChip(context, envelope.source.name.toUpperCase(),
                    AppColors.textSecondary),
              ],
            ),
            // Right: Timestamp
            Text(
              "As of $timeStr",
              style: AppTypography.label(context)
                  .copyWith(fontSize: 10, color: AppColors.textDisabled),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Badges (Wrapped) + Explain Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BadgeStripWidget(
                title: "CONFIDENCE",
                badges: envelope.confidenceBadges
                    .map((e) => e.name.toUpperCase().split('.').last)
                    .toList(),
              ),
            ),
            InkWell(
              onTap: () {
                // D44.13 Explain Trigger
                final dt = envelope.asOfUtc.toUtc();
                final timeStr =
                    "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} UTC";

                EliteExplainNotification("EXPLAIN_ON_DEMAND_RESULT", payload: {
                  "ticker": ticker,
                  "status": envelope.status.name.toUpperCase(),
                  "source": envelope.source.name.toUpperCase(),
                  "timestamp": timeStr,
                  "badges": envelope.confidenceBadges
                      .map((e) => e.name.toUpperCase().split('.').last)
                      .toList()
                }).dispatch(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.neonCyan.withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 12, color: AppColors.neonCyan),
                    const SizedBox(width: 4),
                    Text("EXPLAIN",
                        style: AppTypography.label(context).copyWith(
                            fontSize: 10,
                            color: AppColors.neonCyan,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.label(context)
            .copyWith(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

}

class BadgeStripWidget extends StatelessWidget {
  final String title;
  final List<String> badges;

  const BadgeStripWidget({
    super.key,
    required this.title,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0), // Spacing when wrapping
          child: Text(title,
              style: AppTypography.label(context)
                  .copyWith(color: AppColors.textSecondary)),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: badges
              .map((badge) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.textDisabled),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textDisabled,
                          fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
        )
      ],
    );
  }

}
