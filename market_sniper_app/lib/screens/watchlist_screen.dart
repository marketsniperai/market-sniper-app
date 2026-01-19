import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/watchlist_add_modal.dart';
import '../logic/watchlist_store.dart';
import '../logic/navigation_bus.dart'; // D44.02B
import '../logic/watchlist_ledger.dart'; // D44.02B
import '../logic/data_state_resolver.dart'; // D44.02B
import '../repositories/war_room_repository.dart'; // D44.02B
import '../repositories/dashboard_repository.dart'; // D44.02B
import '../services/api_client.dart'; // D44.02B
import '../widgets/lock_reason_modal.dart'; // D44.02A

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
     final repo = WarRoomRepository(api: api); // Lightweight just for Health check if needed, or SystemHealthRepo direct.
     // Simplified: Just check OS Health & Dashboard Basic
     // Since we don't have a global provider for 'current state' easily accessible without fetching, 
     // we will check SystemHealthRepository.
     
     final healthSnapshot = await repo.healthRepo.fetchUnifiedHealth();
     // We also need dashboard for age check (stale). Fetching dashboard is heavy, 
     // so we might rely on Health 'status' which includes 'DEGRADED' or 'LOCKED'.
     
     final isLocked = healthSnapshot.status.name.toUpperCase().contains('LOCKED');
     final isStale = healthSnapshot.status.name.toUpperCase().contains('DEGRADED') || healthSnapshot.status.name.toUpperCase().contains('MISFIRE');
     
     String resolvedState = "LIVE";
     if (isLocked) resolvedState = "LOCKED";
     else if (isStale) resolvedState = "STALE";

     if (isLocked || isStale) {
        // A. BLOCKED PATH
        // Fetch specific reason
        final lockReason = await repo.fetchLockReason();
        
        if (mounted) {
           showLockReasonModal(
             context, 
             lockReason,
             titleOverride: isLocked ? "SYSTEM LOCKED" : "DATA UNRELIABLE"
           );
        }
        
        // Log to Ledger
        WatchlistLedger().logAction(
          action: "ANALYZE_NOW", 
          ticker: ticker, 
          resolvedState: resolvedState, 
          result: "BLOCKED",
          lockReason: "${lockReason.reasonCode}: ${lockReason.description}"
        );
     } else {
        // B. SUCCESS PATH
        // Navigate to OnDemand (Index 3)
        NavigationBus().navigate(3, arguments: ticker);
        
        // Log to Ledger
        WatchlistLedger().logAction(
          action: "ANALYZE_NOW", 
          ticker: ticker, 
          resolvedState: resolvedState, 
          result: "OPENED_RESULT"
        );
     }
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
       action: SnackBarAction(label: "UNDO", onPressed: () => _store.addTicker(ticker)),
       duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Layout Police: Uses CanonicalScrollContainer logic via SingleChildScrollView + Safe Padding
    // Since we have a list, we use ListView but need the padding.
    
    final tickers = _store.tickers;

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by MainLayout
      body: tickers.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt, size: 48, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    "Watchlist Empty", 
                    style: AppTypography.headline(context).copyWith(color: AppColors.textDisabled)
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add tickers from the Core20 Universe.",
                    style: AppTypography.body(context).copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                 top: 16, 
                 left: 16, 
                 right: 16, 
                 bottom: 100 + MediaQuery.of(context).viewPadding.bottom, // FAB + Nav clearance
              ),
              itemCount: tickers.length,
              itemBuilder: (context, index) {
                final ticker = tickers[index];
                return _buildTickerTile(ticker);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
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
        backgroundColor: AppColors.accentCyan,
        icon: const Icon(Icons.add, color: AppColors.bgPrimary),
        label: Text("ADD TICKER", style: AppTypography.label(context).copyWith(color: AppColors.bgPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTickerTile(String ticker) {
     return Container(
       margin: const EdgeInsets.only(bottom: 12),
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         color: AppColors.surface1,
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: AppColors.borderSubtle),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(
             ticker,
             style: AppTypography.headline(context).copyWith(fontFamily: 'RobotoMono'),
           ),
           Row(
             children: [
               IconButton(
                 icon: const Icon(Icons.analytics, color: AppColors.accentCyan),
                 onPressed: () => _analyze(ticker),
                 tooltip: "Analyze (D44.02)",
               ),
               IconButton(
                 icon: const Icon(Icons.delete_outline, color: AppColors.textDisabled),
                 onPressed: () => _remove(ticker),
                 tooltip: "Remove",
               ),
             ],
           )
         ],
       ),
     );
  }
}
