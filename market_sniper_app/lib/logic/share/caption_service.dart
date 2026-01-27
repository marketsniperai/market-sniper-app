enum CaptionPreset { institutional, minimal, human, teaser }

class CaptionService {
  static String generate(CaptionPreset preset,
      {String? ticker, String? change}) {
    switch (preset) {
      case CaptionPreset.institutional:
        return "MarketSniper Intelligence: Context snapshot for ${ticker ?? 'Market'}. No inference.";
      case CaptionPreset.minimal:
        return "${ticker ?? 'OS'} Snapshot.";
      case CaptionPreset.human:
        return "Checking the ${ticker ?? 'Market'} signals. Here is what I see.";
      case CaptionPreset.teaser:
        return "Something big is moving. Unlock the full context inside MarketSniper.";
    }
  }
}
