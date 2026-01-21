import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../logic/navigation_bus.dart'; // D44.02B
import '../logic/on_demand_intent.dart'; // D44.06
import '../services/api_client.dart'; // D44.05
import '../logic/on_demand_history_store.dart'; // D44.15
import '../logic/standard_envelope.dart'; // D44.07
import '../logic/elite_messages.dart'; // D44.13
import '../widgets/on_demand_context_strip.dart'; // D44.12
import '../layout/main_layout.dart'; // To find ancestor if needed
import 'dart:async'; // StreamSubscription

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


  StandardEnvelope? _result;
  StreamSubscription<NavigationEvent>? _navSubscription;
  final OnDemandHistoryStore _historyStore = OnDemandHistoryStore(); // D44.15
  List<OnDemandHistoryItem> _historyItems = []; // D44.15 Cache

  @override
  void initState() {
    super.initState();
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
        if (_state == OnDemandViewState.result || _state == OnDemandViewState.error) {
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
      FocusScope.of(context).unfocus(); // Dismiss keyboard
    });

    // 3. Real Fetch (D44.05)
    final api = context.findAncestorWidgetOfExactType<MainLayout>() != null 
        ? ApiClient() 
        : ApiClient(); 

    final response = await api.fetchOnDemandContext(input);

    if (!mounted) return;

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
    });

    // D44.15: Record Record Success
    await _historyStore.record(ticker: input);
    if (mounted) _refreshHistory();
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _state = OnDemandViewState.idle;
      _result = null;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Layout Police: Uses Safe Scroll + Padding
    final bottomPadding = 100 + MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by MainLayout
      body: SingleChildScrollView(
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
              style: AppTypography.headline(context).copyWith(fontSize: 24, letterSpacing: 1.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Instant context snapshot",
              style: AppTypography.body(context).copyWith(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            
            if (_usageInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                _usageInfo!,
                style: AppTypography.label(context).copyWith(color: AppColors.accentCyanDim, fontSize: 10),
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
                     label: Text(item.ticker, style: AppTypography.label(context)),
                     backgroundColor: AppColors.surface2,
                     side: const BorderSide(color: AppColors.borderSubtle),
                     onPressed: () {
                        // Prefill (No Auto-Trigger)
                        _controller.text = item.ticker;
                        FocusScope.of(context).requestFocus(); // Better UX, let them hit enter or Analyze
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
                hintStyle: TextStyle(color: AppColors.textDisabled.withValues(alpha: 0.5)),
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
                  borderSide: const BorderSide(color: AppColors.accentCyan),
                ),
                counterText: "",
              ),
              onChanged: _onChanged,
            ),
            
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: AppTypography.body(context).copyWith(color: AppColors.stateLocked, fontSize: 12),
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
                      child: Text("CLEAR", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
                    ),
                   ),
                
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _state == OnDemandViewState.loading ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentCyan,
                      foregroundColor: AppColors.bgPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      disabledBackgroundColor: AppColors.surface2,
                    ),
                    child: _state == OnDemandViewState.loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                        : Text("ANALYZE NOW", style: AppTypography.label(context).copyWith(color: AppColors.bgPrimary, fontWeight: FontWeight.bold)),
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
              Icon(Icons.flash_on, size: 48, color: AppColors.textDisabled.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text(
                "Awaiting request...",
                style: AppTypography.body(context).copyWith(color: AppColors.textDisabled),
              ),
            ],
          ),
        );
      
      case OnDemandViewState.loading:
         return const Center(
           child: Column(
             children: [
                SizedBox(height: 24),
                CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan),
                SizedBox(height: 16),
                Text("Analyzing Global Market Data...", style: TextStyle(color: AppColors.accentCyan)),
             ],
           ),
         );

      case OnDemandViewState.result:
      case OnDemandViewState.error:
        if (_result == null) return const SizedBox.shrink();

        // D44.16 Stale Warning Logic
        bool isStale = _result!.status == EnvelopeStatus.stale;
        if (!isStale) {
           final ageMinutes = DateTime.now().difference(_result!.asOfUtc).inMinutes;
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
              if (isStale) ...[
                 _buildStaleWarning(),
                 const SizedBox(height: 16),
              ],
              // D44.11 Header
              EnvelopePreviewHeader(envelope: _result!, ticker: _controller.text.toUpperCase()),
              
              // D44.12 Context Strip
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: OnDemandContextStrip(
                  envelope: _result!, 
                  ticker: _controller.text.toUpperCase()
                ),
              ),

              const Divider(color: AppColors.borderSubtle, height: 24),
              
              if (_result!.sanitized) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      "[SANITIZED] Content flagged by Lexicon Guard", 
                      style: AppTypography.label(context).copyWith(color: AppColors.stateLocked),
                    ),
                  ),
              ],

              ..._result!.bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: AppColors.accentCyan)),
                    Expanded(child: Text(b, style: AppTypography.body(context))),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              // Footer timestamp removed in D44.11 (Moved to Header)
            ],
          ),
        );
    }
  }
  Widget _buildStaleWarning() {
    final ts = _result!.asOfUtc.toUtc();
    final timeStr = "${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')} UTC";
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.stateStale.withValues(alpha: 0.1), 
        border: Border.all(color: AppColors.stateStale.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
            const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.stateStale),
            const SizedBox(width: 8),
            Text("As of $timeStr · Stale", style: AppTypography.label(context).copyWith(color: AppColors.stateStale)),
         ],
       )
    );
  }
}

class EnvelopePreviewHeader extends StatelessWidget {
  final StandardEnvelope envelope;
  final String ticker;

  const EnvelopePreviewHeader({super.key, required this.envelope, required this.ticker});

  @override
  Widget build(BuildContext context) {
    // 1. Status Chip Color
    Color statusColor;
    switch (envelope.status) {
      case EnvelopeStatus.live: statusColor = AppColors.stateLive; break;
      case EnvelopeStatus.stale: statusColor = AppColors.stateStale; break;
      case EnvelopeStatus.locked: statusColor = AppColors.stateLocked; break;
      case EnvelopeStatus.unavailable: statusColor = AppColors.textDisabled; break;
      case EnvelopeStatus.error: statusColor = AppColors.stateLocked; break;
    }

    // 2. Format Timestamp
    final dt = envelope.asOfUtc.toUtc();
    final timeStr = "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} UTC";

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
                _buildChip(context, envelope.status.name.toUpperCase(), statusColor),
                _buildChip(context, envelope.source.name.toUpperCase(), AppColors.textSecondary),
              ],
            ),
            // Right: Timestamp
            Text(
              "As of $timeStr",
              style: AppTypography.label(context).copyWith(fontSize: 10, color: AppColors.textDisabled),
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
                  badges: envelope.confidenceBadges.map((e) => e.name.toUpperCase().split('.').last).toList(),
                ),
              ),
              InkWell(
                 onTap: () {
                     // D44.13 Explain Trigger
                     final dt = envelope.asOfUtc.toUtc();
                     final timeStr = "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} UTC";
                     
                     EliteExplainNotification(
                        "EXPLAIN_ON_DEMAND_RESULT",
                        payload: {
                           "ticker": ticker, 
                           "status": envelope.status.name.toUpperCase(),
                           "source": envelope.source.name.toUpperCase(),
                           "timestamp": timeStr,
                           "badges": envelope.confidenceBadges.map((e) => e.name.toUpperCase().split('.').last).toList()
                        }
                     ).dispatch(context);
                 },
                 child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                       border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.5)),
                       borderRadius: BorderRadius.circular(16),
                       color: AppColors.accentCyan.withValues(alpha: 0.1),
                    ),
                    child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                          const Icon(Icons.auto_awesome, size: 12, color: AppColors.accentCyan),
                          const SizedBox(width: 4),
                          Text("EXPLAIN", style: AppTypography.label(context).copyWith(fontSize: 10, color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
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
        style: AppTypography.label(context).copyWith(fontSize: 10, color: color, fontWeight: FontWeight.bold),
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
          child: Text(title, style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: badges.map((badge) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.textDisabled),
            ),
            child: Text(
              badge,
              style: const TextStyle(fontSize: 10, color: AppColors.textDisabled, fontWeight: FontWeight.bold),
            ),
          )).toList(),
        )
      ],
    );
  }
}


