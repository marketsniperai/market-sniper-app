import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/news/news_digest_model.dart';
import '../../widgets/news_digest_card.dart';
import '../../logic/news/news_digest_source.dart'; // D47.HF13
import '../../logic/watchlist_store.dart'; // D47.HF13 Watchlist Integration
import 'package:intl/intl.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // D47.HF13: Source Abstraction
  final NewsDigestSource _source = LocalDemoNewsDigestSource();
  
  // State
  late Future<NewsDigestViewModel> _digestFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final watchlist = WatchlistStore().tickers; // Simple sync access from store singleton
    _digestFuture = _source.loadDigest(watchlistSymbols: watchlist);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
    await _digestFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<NewsDigestViewModel>(
                future: _digestFuture,
                builder: (context, snapshot) {
                  // While loading or if we have data, we show the header.
                  // If loading, we use a placeholder or previous data if available?
                  // Simple: render header with empty/loading state if no data yet.
                  
                  final data = snapshot.data;
                  return _buildHeader(data);
                }),
            Expanded(
              child: FutureBuilder<NewsDigestViewModel>(
                future: _digestFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonCyan));
                  } else if (snapshot.hasError) {
                     return _buildDegradedState(error: snapshot.error.toString());
                  } else if (!snapshot.hasData || snapshot.data!.items.isEmpty) {
                    return _buildDegradedState();
                  }

                  final data = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.neonCyan,
                    backgroundColor: AppColors.surface2,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.items.length,
                      itemBuilder: (context, index) {
                        return NewsDigestCard(item: data.items[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(NewsDigestViewModel? data) {
    // defaults
    var timeStr = "--:--";
    Color freshnessColor = AppColors.textDisabled;
    String freshnessLabel = "LOADING...";
    String sourceName = "---";

    if (data != null) {
        timeStr = DateFormat('HH:mm').format(data.asOfUtc);
        sourceName = data.source.name.toUpperCase();
        
        switch (data.freshness) {
          case DigestFreshness.live:
            freshnessColor = AppColors.stateLive;
            freshnessLabel = "LIVE";
            break;
          case DigestFreshness.stale:
          case DigestFreshness.delayed:
            freshnessColor = AppColors.stateStale;
            freshnessLabel = "DELAYED";
            break;
          case DigestFreshness.demo: // D47
            freshnessColor = AppColors.neonCyan; // Premium
            freshnessLabel = "DEMO MODE";
            break;
          case DigestFreshness.offline:
          default:
            freshnessColor = AppColors.textDisabled;
            freshnessLabel = "OFFLINE";
            break;
        }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DAILY DIGEST",
                style: AppTypography.title(context).copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: freshnessColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: freshnessColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  freshnessLabel,
                  style: TextStyle(
                      color: freshnessColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "SOURCE: $sourceName • AS OF $timeStr UTC",
                style: GoogleFonts.robotoMono(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDegradedState({String? error}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox,
              size: 48, color: AppColors.textDisabled.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            error ?? "No digest available",
            style: GoogleFonts.inter(color: AppColors.textDisabled),
            textAlign: TextAlign.center,
          ),
          if (error != null) 
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Text("Error: $error", style: const TextStyle(color: AppColors.marketBear, fontSize: 10)),
             )
        ],
      ),
    );
  }
}
