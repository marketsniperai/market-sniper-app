enum CalendarFreshness { live, stale, delayed, offline }

enum CalendarSource { pipeline, cache, offline }

enum EventImpact { high, medium, low }

enum EventCategory { macro, earnings, other }

class CalendarEvent {
  final String id;
  final String title;
  final DateTime timeUtc;
  final EventCategory category;
  final EventImpact impact;
  final String source; // e.g., "BLS", "FED", "AAPL"

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.timeUtc,
    required this.category,
    required this.impact,
    required this.source,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    // Parse Category
    EventCategory cat = EventCategory.other;
    final cStr = json['category']?.toString().toUpperCase() ?? '';
    if (cStr == 'MACRO') cat = EventCategory.macro;
    else if (cStr == 'EARNINGS') cat = EventCategory.earnings;

    // Parse Impact
    EventImpact imp = EventImpact.low;
    final iStr = json['impact']?.toString().toUpperCase() ?? '';
    if (iStr == 'HIGH') imp = EventImpact.high;
    else if (iStr == 'MEDIUM') imp = EventImpact.medium;

    return CalendarEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Event',
      timeUtc: DateTime.tryParse(json['timeUtc'] ?? '') ?? DateTime.now(),
      category: cat,
      impact: imp,
      source: json['source'] ?? 'Unknown',
    );
  }
}

class EconomicCalendarViewModel {
  final CalendarFreshness freshness;
  final CalendarSource source;
  final DateTime asOfUtc;
  final List<CalendarEvent> events;

  const EconomicCalendarViewModel({
    required this.freshness,
    required this.source,
    required this.asOfUtc,
    required this.events,
  });

  static EconomicCalendarViewModel offline() {
    return EconomicCalendarViewModel(
      freshness: CalendarFreshness.offline,
      source: CalendarSource.offline,
      asOfUtc: DateTime.now().toUtc(),
      events: [],
    );
  }

  factory EconomicCalendarViewModel.fromJson(Map<String, dynamic> json) {
    // Parse Source
    CalendarSource src = CalendarSource.offline;
    final sStr = json['source']?.toString().toUpperCase() ?? 'OFFLINE';
    if (sStr.contains('PIPELINE')) src = CalendarSource.pipeline;
    else if (sStr.contains('DEMO')) src = CalendarSource.cache; // Treat demo as cache/grade

    // Parse Events
    List<CalendarEvent> evts = [];
    if (json['events'] != null) {
      evts = (json['events'] as List).map((e) => CalendarEvent.fromJson(e)).toList();
    }

    // Parse Timestamp
    DateTime ts = DateTime.now().toUtc();
    if (json['asOfUtc'] != null) {
      ts = DateTime.tryParse(json['asOfUtc']) ?? ts;
    }

    return EconomicCalendarViewModel(
      freshness: CalendarFreshness.live, // Assume live if we got JSON
      source: src,
      asOfUtc: ts,
      events: evts,
    );
  }
}

// Fixed: Moved parser into class to support CalendarEvent.fromJson
