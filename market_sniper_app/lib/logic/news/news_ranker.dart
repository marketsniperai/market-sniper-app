import '../../models/news/news_digest_model.dart';

enum NewsBucket { macro, watchlist, general }

enum RecencyBucket { last15m, last60m, today, older }

class NewsRanker {
  // D47.HF14: Canonical Macro Keywords (Deterministic)
  static const List<String> _macroKeywords = [
    "FED",
    "FOMC",
    "CPI",
    "PCE",
    "NFP",
    "JOBS",
    "INFLATION",
    "TREASURY",
    "YIELD",
    "GEOPOLITICS",
    "OPEC",
    "RATES",
    "CENTRAL BANK"
  ];

  /// Main Ranking Function
  /// Sorts by: Bucket (Macro > Watchlist > General) -> Recency -> Timestamp Desc
  static List<NewsDigestItem> rank(
    List<NewsDigestItem> items, {
    required Set<String> watchlistSymbols,
    required DateTime nowUtc,
  }) {
    // 1. Annotate items with ranking metadata (Bucket + Recency)
    // We create a wrapper or just compute on the fly. To keep it clean and return modified items with reason,
    // we map to a temporary structure, sort, then map back to copies with reason set.

    final wrapped = items.map((item) {
      final bucket = _computeBucket(item, watchlistSymbols);
      final recency = _computeRecency(item, nowUtc);
      return _RankedWrapper(item, bucket, recency);
    }).toList();

    // 2. Sort
    wrapped.sort((a, b) {
      // Primary: Bucket Priority (Lower index = Higher priority)
      // macro (0) < watchlist (1) < general (2)
      final bucketCompare = a.bucket.index.compareTo(b.bucket.index);
      if (bucketCompare != 0) return bucketCompare;

      // Secondary: Recency (Lower index = Newer/Higher priority)
      // last15m (0) < ... < older (3)
      final recencyCompare = a.recency.index.compareTo(b.recency.index);
      if (recencyCompare != 0) return recencyCompare;

      // Tertiary: Timestamp Descending (Newest first)
      return b.item.publishedUtc.compareTo(a.item.publishedUtc);
    });

    // 3. Unwrap and Inject Reason
    return wrapped.map((w) {
      final reason =
          "${w.bucket.name.toUpperCase()} • ${w.recency.name.toUpperCase()}";
      
      // Return copy with reason (using constructor since fields are final)
      return NewsDigestItem(
        id: w.item.id,
        title: w.item.title,
        source: w.item.source,
        publishedUtc: w.item.publishedUtc,
        impact: w.item.impact,
        summaryBrief: w.item.summaryBrief,
        summaryExpand: w.item.summaryExpand,
        symbols: w.item.symbols,
        rankingReason: reason,
      );
    }).toList();
  }

  static NewsBucket _computeBucket(
      NewsDigestItem item, Set<String> watchlistSymbols) {
    // 1. MACRO Check
    // Check title/summary/symbols for keywords
    final text =
        "${item.title} ${item.summaryBrief} ${item.symbols.join(' ')}"
            .toUpperCase();
    
    for (final kw in _macroKeywords) {
      if (text.contains(kw)) {
        return NewsBucket.macro;
      }
    }

    // 2. WATCHLIST Check
    // If any symbol in item is in user's watchlist
    if (item.symbols.isNotEmpty) {
      // Normalize symbols to uppercase just in case
      final itemSybmols = item.symbols.map((s) => s.toUpperCase()).toSet();
      // Watchlist symbols are expected to be uppercase from Store, but verify logic safety
      if (watchlistSymbols.any((ws) => itemSybmols.contains(ws))) {
        return NewsBucket.watchlist;
      }
    }

    // 3. Fallback
    return NewsBucket.general;
  }

  static RecencyBucket _computeRecency(NewsDigestItem item, DateTime nowUtc) {
    final age = nowUtc.difference(item.publishedUtc).abs(); // abs to handle slight clock skew safe

    if (age < const Duration(minutes: 15)) {
      return RecencyBucket.last15m;
    } else if (age < const Duration(minutes: 60)) {
      return RecencyBucket.last60m;
    } else if (age < const Duration(hours: 24)) {
      return RecencyBucket.today;
    } else {
      return RecencyBucket.older;
    }
  }
}

class _RankedWrapper {
  final NewsDigestItem item;
  final NewsBucket bucket;
  final RecencyBucket recency;

  _RankedWrapper(this.item, this.bucket, this.recency);
}
