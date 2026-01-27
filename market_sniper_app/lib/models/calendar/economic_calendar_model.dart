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
}
