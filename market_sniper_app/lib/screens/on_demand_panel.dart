import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../domain/universe/core20_universe.dart';
import '../logic/navigation_bus.dart'; // D44.02B
import '../services/api_client.dart'; // D44.05
import '../layout/main_layout.dart'; // To find ancestor if needed
import 'dart:async'; // StreamSubscription

enum OnDemandViewState { idle, loading, result, error }

class OnDemandResult {
  final String ticker;
  final DateTime generatedAt;
  final String status;
  final List<String> bullets;

  OnDemandResult({
    required this.ticker,
    required this.generatedAt,
    required this.status,
    required this.bullets,
  });
}

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


  OnDemandResult? _result;
  StreamSubscription<NavigationEvent>? _navSubscription;

  @override
  void initState() {
    super.initState();
    _navSubscription = NavigationBus().events.listen((event) {
      // If we are targeted (index 3) and have string arg, use it as ticker
      if (event.tabIndex == 3 && event.arguments is String) {
        final ticker = event.arguments as String;
        _controller.text = ticker;
        _analyze(); // D44.02B Auto-trigger analysis
      }
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

    // 1. Validate Universe (Institutional Guard)
    if (!CoreUniverse.isCore20(input)) {
      setState(() {
        _errorText = "Institutional Guard: Symbol not in CORE20 universe yet.\nExtended Universe unlocks in D39.02.";
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
         _errorText = "Daily Limit Reached (Resets 04:00 ET)";
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
      
      final freshness = response["freshness"] ?? "UNKNOWN";
      final source = response["source"] ?? "UNKNOWN";
      final payload = response["payload"] ?? {};
      final globalRisk = payload["global_risk"] ?? "UNKNOWN";
      final regime = payload["regime"] ?? "UNKNOWN";
      final ts = response["timestamp_utc"] ?? DateTime.now().toIso8601String();
      
      _result = OnDemandResult(
        ticker: input,
        generatedAt: DateTime.tryParse(ts) ?? DateTime.now(),
        status: freshness, 
        bullets: [
          "Ticker: $input",
          "Universe: CORE20", // Still guarded
          "Source: $source",
          "Risk State: $globalRisk",
          "Regime: $regime",
        ],
      );
    });
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
                Text("Fetching snapshot...", style: TextStyle(color: AppColors.accentCyan)),
             ],
           ),
         );

      case OnDemandViewState.result:
      case OnDemandViewState.error:
        if (_result == null) return const SizedBox.shrink();

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ON-DEMAND RESULT", style: AppTypography.label(context).copyWith(color: AppColors.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.textDisabled),
                    ),
                    child: Text(
                      _result!.status,
                      style: const TextStyle(fontSize: 10, color: AppColors.textDisabled, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const Divider(color: AppColors.borderSubtle, height: 24),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                   Text(
                     "Generated locally at ${_result!.generatedAt.hour.toString().padLeft(2,'0')}:${_result!.generatedAt.minute.toString().padLeft(2,'0')}",
                     style: const TextStyle(fontSize: 10, color: AppColors.textDisabled),
                   ),
                ],
              )
            ],
          ),
        );
    }
  }
}
