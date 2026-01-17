// import 'package:flutter/foundation.dart';

class SymbolDefinition {
  final String symbol;
  final String displayLabel;
  final String category;
  final String description;

  const SymbolDefinition({
    required this.symbol,
    required this.displayLabel,
    required this.category,
    required this.description,
  });
}

/// CORE_UNIVERSE
/// Canonical market universe (21 symbols).
/// NOTE: "CORE20" is a historical legacy name retained for continuity.
/// Do NOT rely on numeric interpretation of the name.
class CoreUniverse {
  // Explicit Alias Map: Input -> Canonical Symbol
  static const Map<String, String> aliases = {
    'BTC': 'X:BTCUSD',
    'BTCUSD': 'X:BTCUSD',
    'US02Y': 'US2Y',
  };

  static const List<SymbolDefinition> definitions = [
    // Indices (4)
    SymbolDefinition(symbol: 'SPX', displayLabel: 'SPX', category: 'Indices', description: 'S&P 500'),
    SymbolDefinition(symbol: 'NDX', displayLabel: 'NDX', category: 'Indices', description: 'Nasdaq 100'),
    SymbolDefinition(symbol: 'RUT', displayLabel: 'RUT', category: 'Indices', description: 'Russell 2000'),
    SymbolDefinition(symbol: 'DJI', displayLabel: 'DJI', category: 'Indices', description: 'Dow Jones'),

    // Rates (2)
    SymbolDefinition(symbol: 'US10Y', displayLabel: 'US10Y', category: 'Rates', description: 'US 10 Year Yield'),
    SymbolDefinition(symbol: 'US2Y', displayLabel: 'US2Y', category: 'Rates', description: 'US 2 Year Yield'),

    // Dollar (1)
    SymbolDefinition(symbol: 'DXY', displayLabel: 'DXY', category: 'Dollar', description: 'US Dollar Index'),

    // Commodities (2)
    SymbolDefinition(symbol: 'CL', displayLabel: 'Crude', category: 'Commodities', description: 'Crude Oil'),
    SymbolDefinition(symbol: 'GC', displayLabel: 'Gold', category: 'Commodities', description: 'Gold Futures'),

    // Crypto (1)
    SymbolDefinition(symbol: 'X:BTCUSD', displayLabel: 'BTCUSD', category: 'Crypto', description: 'Bitcoin'),

    // Volatility (1)
    SymbolDefinition(symbol: 'VIX', displayLabel: 'VIX', category: 'Volatility', description: 'CBOE Volatility Index'),

    // Sectors (10)
    SymbolDefinition(symbol: 'XLF', displayLabel: 'XLF', category: 'Sectors', description: 'Financials'),
    SymbolDefinition(symbol: 'XLK', displayLabel: 'XLK', category: 'Sectors', description: 'Technology'),
    SymbolDefinition(symbol: 'XLE', displayLabel: 'XLE', category: 'Sectors', description: 'Energy'),
    SymbolDefinition(symbol: 'XLY', displayLabel: 'XLY', category: 'Sectors', description: 'Discretionary'),
    SymbolDefinition(symbol: 'XLI', displayLabel: 'XLI', category: 'Sectors', description: 'Industrials'),
    SymbolDefinition(symbol: 'XLP', displayLabel: 'XLP', category: 'Sectors', description: 'Staples'),
    SymbolDefinition(symbol: 'XLV', displayLabel: 'XLV', category: 'Sectors', description: 'Health Care'),
    SymbolDefinition(symbol: 'XLB', displayLabel: 'XLB', category: 'Sectors', description: 'Materials'),
    SymbolDefinition(symbol: 'XLU', displayLabel: 'XLU', category: 'Sectors', description: 'Utilities'),
    SymbolDefinition(symbol: 'XLC', displayLabel: 'XLC', category: 'Sectors', description: 'Comm Services'),
  ];

  /// Returns the canonical symbol if the input maps to a Core20 symbol, or null otherwise.
  static String? normalizeSymbol(String input) {
    if (input.isEmpty) return null;
    final normalized = input.trim().toUpperCase();
    
    // 1. Check strict alias
    if (aliases.containsKey(normalized)) {
      return aliases[normalized];
    }

    // 2. Check canonical symbols directly
    // OPTIMIZATION: In a larger set we'd use a Set lookup, but for 20 items list iteration is negligible.
    for (var def in definitions) {
      if (def.symbol == normalized) {
        return def.symbol;
      }
    }

    return null;
  }

  static bool isCore20(String symbol) {
    return normalizeSymbol(symbol) != null;
  }
  
  static SymbolDefinition? getDefinition(String symbol) {
      final canonical = normalizeSymbol(symbol);
      if (canonical == null) return null;
      
      try {
        return definitions.firstWhere((d) => d.symbol == canonical);
      } catch (e) {
        return null;
      }
  }
}
