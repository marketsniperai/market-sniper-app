class OnDemandIntent {
  final String ticker;
  final bool autoTrigger;
  final String source; // "WATCHLIST_TAP", "WATCHLIST_ANALYZE", etc.
  final DateTime timestampUtc;

  OnDemandIntent({
    required this.ticker,
    required this.autoTrigger,
    required this.source,
    required this.timestampUtc,
  });

  @override
  String toString() => 'OnDemandIntent(ticker: $ticker, autoTrigger: $autoTrigger, source: $source)';
}
