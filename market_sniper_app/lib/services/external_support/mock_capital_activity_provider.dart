import 'capital_activity_provider.dart';

class MockCapitalActivityProvider implements CapitalActivityProvider {
  @override
  Future<CapitalActivityResult> fetchActivity(String symbol) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Determinstic Mock Data based on Symbol char code
    // This allows "stable" mocks for specific symbols
    final int hash = symbol.codeUnitAt(0);

    if (hash % 3 == 0) {
      return CapitalActivityResult.mock(
        summary: "High volume call interaction detected at \$${(hash * 2).toString()}.",
        bias: "Bullish",
      );
    } else if (hash % 3 == 1) {
       return CapitalActivityResult.mock(
        summary: "Institutional put protection layers active.",
        bias: "Bearish",
      );
    } else {
       return CapitalActivityResult.mock(
        summary: "Mixed flow with no clear directional bias.",
        bias: "Mixed",
      );
    }
  }
}
