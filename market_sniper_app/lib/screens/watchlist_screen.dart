import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/watchlist_add_modal.dart';
import '../logic/watchlist_store.dart';
import '../logic/navigation_bus.dart'; // D44.02B
import '../logic/watchlist_ledger.dart'; // D44.02B
import '../repositories/war_room_repository.dart'; // D44.02B
import '../services/api_client.dart'; // D44.02B
import '../widgets/lock_reason_modal.dart'; // D44.02A
import '../logic/on_demand_intent.dart'; // D44.06
import '../logic/watchlist_state_resolver.dart'; // D44.09
import '../logic/watchlist_last_analyzed_resolver.dart'; // D44.10

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final WatchlistStore _store = WatchlistStore();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreUpdate);
    _store.init(); // Ensure loaded
    _refreshGlobalState(); // D44.09
  }

  // D44.09
  final WatchlistStateResolver _stateResolver = WatchlistStateResolver();
  // D44.10
  final WatchlistLastAnalyzedResolver _timestampResolver =
      WatchlistLastAnalyzedResolver();

  Future<void> _refreshGlobalState() async {
    try {
      final api = ApiClient();
      final repo = WarRoomRepository(api: api);
      final health = await repo.healthRepo.fetchUnifiedHealth();
      if (mounted) {
        setState(() {
          _stateResolver.setGlobalStateFromHealth(health.status.name);
        });
      }
    } catch (e) {
      // Silent fail to LIVE or keep default
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _analyze(String ticker) async {
    // D44.02B Real Flow
    // 1. Resolve State
    // Ideally we'd have a cached health/dashboard state, but for now we do a fresh check or assume nominal for speed if no cache provider.
    // To be robust, we fetch unified health via Repo.

    final api = ApiClient(); // In a real app, use provider/GetIt
    final repo = WarRoomRepository(
        api:
            api); // Lightweight just for Health check if needed, or SystemHealthRepo direct.
    // Simplified: Just check OS Health & Dashboard Basic
    // Since we don't have a global provider for 'current state' easily accessible without fetching,
    // we will check SystemHealthRepository.

    final healthSnapshot = await repo.healthRepo.fetchUnifiedHealth();
    // We also need dashboard for age check (stale). Fetching dashboard is heavy,
    // so we might rely on Health 'status' which includes 'DEGRADED' or 'LOCKED'.

    final isLocked =
        healthSnapshot.status.name.toUpperCase().contains('LOCKED');
    final isStale =
        healthSnapshot.status.name.toUpperCase().contains('DEGRADED') ||
            healthSnapshot.status.name.toUpperCase().contains('MISFIRE');

    String resolvedState = "LIVE";
    if (isLocked) {
      resolvedState = "LOCKED";
    } else if (isStale) {
      resolvedState = "STALE";
    }

    if (isLocked || isStale) {
      // A. BLOCKED PATH
      // Fetch specific reason
      final lockReason = await repo.fetchLockReason();

      if (mounted) {
        showLockReasonModal(context, lockReason,
            titleOverride: isLocked ? "SYSTEM LOCKED" : "DATA UNRELIABLE");
      }

      // Log to Ledger
      WatchlistLedger().logAction(
          action: "ANALYZE_NOW",
          ticker: ticker,
          resolvedState: resolvedState,
          result: "BLOCKED",
          lockReason: "${lockReason.reasonCode}: ${lockReason.description}");
    } else {
      // B. SUCCESS PATH (D44.06 Integration)
      // Navigate to OnDemand (Index 3) with Intent
      NavigationBus().navigate(3,
          arguments: OnDemandIntent(
            ticker: ticker,
            autoTrigger: true,
            source: "WATCHLIST_ANALYZE",
            timestampUtc: DateTime.now().toUtc(),
          ));

      // Log to Ledger
      WatchlistLedger().logAction(
          action: "ANALYZE_NOW",
          ticker: ticker,
          resolvedState: resolvedState,
          result: "OPENED_RESULT");
    }
  }

  void _onTickerTap(String ticker) {
    // D44.06: Tap to Prefill (No Auto-Trigger)
    NavigationBus().navigate(3,
        arguments: OnDemandIntent(
          ticker: ticker,
          autoTrigger: false,
          source: "WATCHLIST_TAP",
          timestampUtc: DateTime.now().toUtc(),
        ));
  }

  void _remove(String ticker) {
    _store.removeTicker(ticker);

    // D44.03 Logging
    WatchlistLedger().logAction(
        action: "REMOVE",
        ticker: ticker,
        resolvedState: "LIVE", // Assume live for removal context
        result: "SUCCESS" // Maps to backend Outcome
        );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Removed $ticker"),
      action: SnackBarAction(
          label: "UNDO", onPressed: () => _store.addTicker(ticker)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Layout Police: Uses CanonicalScrollContainer logic via SingleChildScrollView + Safe Padding
    // Since we have a list, we use ListView but need the padding.

    final tickers = _store.tickers;

    return Stack(
      children: [
        tickers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.list_alt,
                        size: 48, color: AppColors.textDisabled),
                    const SizedBox(height: 16),
                    Text("Watchlist Empty",
                        style: AppTypography.headline(context)
                            .copyWith(color: AppColors.textDisabled)),
                    const SizedBox(height: 8),
                    Text(
                      "Add tickers from the Core20 Universe.",
                      style: AppTypography.body(context)
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.only(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 100 +
                      MediaQuery.of(context)
                          .viewPadding
                          .bottom, // FAB + Nav clearance
                ),
                itemCount: tickers.length,
                itemBuilder: (context, index) {
                  final ticker = tickers[index];
                  return _TickerTile(
                      ticker: ticker,
                      stateResolver: _stateResolver,
                      timestampResolver:
                          _timestampResolver, // Pass to sub-widget for FutureBuilder isolation
                      onTap: _onTickerTap,
                      onAnalyze: _analyze,
                      onRemove: _remove);
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface1,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => const WatchlistAddModal(),
              );
            },
            backgroundColor: AppColors.neonCyan,
            icon: const Icon(Icons.add, color: AppColors.bgPrimary),
            label: Text("ADD TICKER",
                style: AppTypography.label(context).copyWith(
                    color: AppColors.bgPrimary, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _TickerTile extends StatelessWidget {
  final String ticker;
  final WatchlistStateResolver stateResolver;
  final WatchlistLastAnalyzedResolver timestampResolver;
  final Function(String) onTap;
  final Function(String) onAnalyze;
  final Function(String) onRemove;

  const _TickerTile({
    required this.ticker,
    required this.stateResolver,
    required this.timestampResolver,
    required this.onTap,
    required this.onAnalyze,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTap(ticker),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticker,
                      style: AppTypography.headline(context)
                          .copyWith(fontFamily: 'RobotoMono'),
                    ),
                    const SizedBox(height: 4),
                    // D44.10 Timestamp
                    FutureBuilder<DateTime?>(
                      future: timestampResolver.resolve(ticker),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return const SizedBox.shrink();
                        }
                        final dt = snapshot.data!.toUtc();
                        final timeStr =
                            "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                        return Text(
                          "Last analyzed · $timeStr UTC",
                          style: AppTypography.label(context).copyWith(
                              fontSize: 10, color: AppColors.textDisabled),
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    // D44.09 State Chip
                    StateChip(state: stateResolver.resolve(ticker)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.analytics,
                          color: AppColors.neonCyan),
                      onPressed: () => onAnalyze(ticker),
                      tooltip: "Analyze (D44.02)",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.textDisabled),
                      onPressed: () => onRemove(ticker),
                      tooltip: "Remove",
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StateChip extends StatelessWidget {
  final WatchlistTickerState state;

  const StateChip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (state) {
      case WatchlistTickerState.live:
        color = AppColors.stateLive;
        label = "LIVE";
        break;
      case WatchlistTickerState.stale:
        color = AppColors.stateStale;
        label = "STALE";
        break;
      case WatchlistTickerState.locked:
        color = AppColors.stateLocked;
        label = "LOCKED";
        break;
    }

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
            .copyWith(fontSize: 9, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
