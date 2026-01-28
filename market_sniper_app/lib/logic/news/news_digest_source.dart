import '../../models/news/news_digest_model.dart';
import 'news_ranker.dart'; // D47.HF14

/// Abstract contract for fetching the Daily Digest.
/// Allows swapping between [LocalDemoNewsDigestSource] and future [ApiNewsDigestSource].
abstract class NewsDigestSource {
  Future<NewsDigestViewModel> loadDigest({List<String>? watchlistSymbols});
}

/// Deterministic Demo Source for Day 47.
/// Provides a "Premium Demo" experience with realistic mock data.
class LocalDemoNewsDigestSource implements NewsDigestSource {
  @override
  Future<NewsDigestViewModel> loadDigest(
      {List<String>? watchlistSymbols}) async {
    // Simulate network delay for realism
    await Future.delayed(const Duration(milliseconds: 800));

    // Deterministic Demo Items
    // D47.HF14: Added meaningful symbols for Ranking testing
    final items = [
      NewsDigestItem(
        id: "demo_01",
        title: "Fed Signals Pause as Inflation Data Cools Below 3%",
        source: "MacroWire",
        publishedUtc: DateTime.now().toUtc().subtract(const Duration(minutes: 15)),
        impact: DigestImpact.high,
        summaryBrief:
            "Federal Reserve officials indicated a high likelihood of pausing rate hikes in the upcoming meeting following softer-than-expected CPI print.",
        summaryExpand:
            "The Bureau of Labor Statistics reported a 2.9% year-over-year increase in CPI, marking the first time inflation has dipped below 3% in over two years. Markets reacted positively, with Treasury yields falling across the curve. Fed Governor Waller stated, 'We are seeing the progress we hoped for,' suggesting the hiking cycle may be at its terminal rate for 2026.",
        symbols: ["SPY", "QQQ", "FED"], // Triggers Macro
      ),
      NewsDigestItem(
        id: "demo_02",
        title: "Tech Sector Rally: NVDA & AMD Lead Semiconductor Breakout",
        source: "TechDaily",
        publishedUtc: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        impact: DigestImpact.medium,
        summaryBrief:
            "Semiconductor stocks surged in pre-market trading, driven by renewed AI demand forecasts and upgrades from major analysts.",
        summaryExpand:
            "Both NVIDIA and AMD posted 3% gains in early trading after Goldman Sachs raised price targets for the sector. The note highlighted 'insatiable demand' for data center GPUs. The SOXX index is testing new all-time highs as the rotation back into growth stocks gains momentum.",
        symbols: ["NVDA", "AMD", "SOXX", "XLK"], // Triggers Watchlist if user watches these
      ),
      NewsDigestItem(
        id: "demo_03",
        title: "Oil Prices Dip on Inventory Build",
        source: "Commodity Watch",
        publishedUtc: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
        impact: DigestImpact.low,
        summaryBrief:
            "WTI Crude fell 1.5% to \$74/bbl after EIA reported a larger-than-expected inventory build of 3.5M barrels.",
        summaryExpand:
            "Supply concerns eased as US production hit record levels. Analyzing the spread, crack spreads remain healthy, but the immediate impulse is bearish for the Energy sector (XLE). Traders are now looking to OPEC+ for any potential supply cuts in the next meeting.",
        symbols: ["XLE", "USO", "CL=F"],
      ),
    ];

    // Priority Demo Logic: If user watches 'BTC' (or crypto-like), inject a crypto item.
    if (watchlistSymbols != null &&
        watchlistSymbols.any((s) => s.contains("BTC") || s.contains("ETH"))) {
      items.insert(
          1,
          NewsDigestItem(
            id: "demo_crypto_01",
            title: "Bitcoin Reclaims \$68k Resistance Level",
            source: "CryptoDesk",
            publishedUtc:
                DateTime.now().toUtc().subtract(const Duration(minutes: 5)), // Recency test (5m ago)
            impact: DigestImpact.medium,
            summaryBrief:
                "BTC/USD broke through key resistance at \$68,000, triggering a short squeeze in perpetual futures.",
            summaryExpand:
                "On-chain data shows a spike in accumulation by commercial whales. The move coincides with a weakening DXY. Analysts suggest the next technical target lies at \$72,000 if support holds above the moving averages.",
            symbols: ["BTC-USD", "COIN", "MSTR"],
          ));
    }

    // D47.HF14: Apply deterministic ranking
    // 1. Prepare safe watchlist set
    final safeWatchlist = (watchlistSymbols ?? []).toSet();
    final nowUtc = DateTime.now().toUtc();

    // 2. Rank
    final rankedItems = NewsRanker.rank(items,
        watchlistSymbols: safeWatchlist, nowUtc: nowUtc);

    return NewsDigestViewModel(
      freshness: DigestFreshness.demo, 
      source: DigestSource.offline, // Demo source is basically offline/local
      asOfUtc: nowUtc,
      items: rankedItems,
    );
  }
}
