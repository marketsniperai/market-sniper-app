import 'dart:convert';
import 'package:market_sniper_app/logic/day_memory_store.dart';
import 'package:market_sniper_app/logic/session_thread_memory_store.dart';

class EliteContextualRecallSnapshot {
  final String timestampLocal;
  final List<String> bullets;
  final List<String> sourcesUsed;
  final String status; // SUCCESS | EMPTY | UNAVAILABLE

  EliteContextualRecallSnapshot({
    required this.timestampLocal,
    required this.bullets,
    required this.sourcesUsed,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'timestamp_local': timestampLocal,
        'bullets': bullets,
        'sources_used': sourcesUsed,
        'status': status,
      };
}

class EliteContextualRecallEngine {
  static const int MAX_BULLETS = 3;
  static const int MAX_CHARS_PER_BULLET = 160;
  static const int MAX_TOTAL_BYTES = 4096;

  /// deterministic keyword mapping for DayMemory signal extraction
  static const Map<String, String> _domainKeywords = {
    'RISK': 'GLOBAL_RISK',
    'VIX': 'GLOBAL_RISK',
    'MARKET': 'MARKET_REGIME',
    'SPY': 'MARKET_REGIME',
    'QQQ': 'MARKET_REGIME',
    'STATUS': 'OS_STATUS',
    'LIVE': 'OS_STATUS',
    'STALE': 'OS_STATUS',
    'LOCKED': 'OS_STATUS',
    'OVERLAY': 'OVERLAY',
    'RITUAL': 'RITUAL',
    'BRIEFING': 'RITUAL',
    'EXPLAIN': 'EXPLAINER',
  };

  Future<EliteContextualRecallSnapshot> build() async {
    final sources = <String>[];
    final bullets = <String>[];

    // 1. Check for Micro-Briefing (Highest Priority)
    final dayMemoryBullets = DayMemoryStore().getBullets();
    // Look for the specific key-value pattern: "MICRO_BRIEFING_OPEN: ..."
    // The previous implementation appends "MICRO_BRIEFING_OPEN: <text>"
    // We want to extract the meaningful content.

    String? microBriefingText;
    // Iterate reverse to find latest
    for (final b in dayMemoryBullets.reversed) {
      if (b.contains("MICRO_BRIEFING_OPEN:")) {
        microBriefingText = b.split("MICRO_BRIEFING_OPEN:")[1].trim();
        break;
      }
    }

    if (microBriefingText != null && microBriefingText.isNotEmpty) {
      // If we have a briefing, that IS the recall context.
      // Parse it back into bullets if possible, or just use it as one block?
      // The text was: "MICRO-BRIEFING ON OPEN\n• Bullet 1\n• Bullet 2..."
      // We can try to split by "•"
      final parts = microBriefingText.split("•");
      if (parts.length > 1) {
        // Skip index 0 usually as it's the header
        for (int i = 1; i < parts.length; i++) {
          if (bullets.length >= MAX_BULLETS) break;
          bullets.add(parts[i].trim());
        }
      } else {
        // Just take the text if no bullets found (fallback)
        bullets.add(microBriefingText);
      }
      sources.add("MICRO_BRIEFING_OPEN");
    }

    // 2. If we have room, scan DayMemory for high-signal items
    if (bullets.length < MAX_BULLETS) {
      final domainMap = <String, String>{}; // Domain -> Latest Bullet

      for (final b in dayMemoryBullets.reversed) {
        // Skip if already used (briefing)
        if (b.contains("MICRO_BRIEFING_OPEN")) continue;
        if (b.contains("CONTEXTUAL_RECALL_LAST")) continue; // Avoid loops

        String? foundDomain;
        for (final entry in _domainKeywords.entries) {
          if (b.toUpperCase().contains(entry.key)) {
            foundDomain = entry.value;
            break;
          }
        }

        if (foundDomain != null) {
          if (!domainMap.containsKey(foundDomain)) {
            domainMap[foundDomain] = b;
          }
        }
      }

      // Add distinct domains to bullets
      for (final b in domainMap.values) {
        if (bullets.length >= MAX_BULLETS) break;
        bullets.add(b);
      }
      if (domainMap.isNotEmpty) sources.add("DAY_MEMORY");
    }

    // 3. If still empty (or low), check Session Thread
    if (bullets.length < MAX_BULLETS) {
      final turns = SessionThreadMemoryStore().getTurns();
      if (turns.isNotEmpty) {
        // Take the last interaction (User + Elite)
        // Turns are maps {role: ..., content: ...}
        // We want to summarize the last exchange.
        final lastTurn = turns.last;
        final role = lastTurn['role'] ?? "UNKNOWN";
        final content = lastTurn['content'] ?? "";

        // "Last Interaction ([ROLE]): [Content]"
        bullets.add("Last $role: $content");
        sources.add("SESSION_THREAD");
      }
    }

    // 4. Final Constraints
    final cleanBullets = bullets.map((b) => _sanitize(b)).toList();
    final status = cleanBullets.isEmpty ? "EMPTY" : "SUCCESS";

    // Check 4KB Limit (Rough JSON check)
    // If too big, drop last bullet until fits
    while (cleanBullets.isNotEmpty) {
      final jsonStr = jsonEncode(cleanBullets);
      if (utf8.encode(jsonStr).length <= MAX_TOTAL_BYTES) break;
      cleanBullets.removeLast();
    }

    return EliteContextualRecallSnapshot(
      timestampLocal: DateTime.now().toString(),
      bullets: cleanBullets,
      sourcesUsed: sources,
      status: status,
    );
  }

  String _sanitize(String input) {
    var text = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > MAX_CHARS_PER_BULLET) {
      text = "${text.substring(0, MAX_CHARS_PER_BULLET - 3)}...";
    }
    return text;
  }
}
