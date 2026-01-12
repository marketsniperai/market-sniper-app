class DashboardWidget {
  final String id;
  final String type;
  final String title;
  final Map<String, dynamic> data;

  DashboardWidget({
    required this.id,
    required this.type,
    required this.title,
    required this.data,
  });

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'] ?? '',
      type: json['type'] ?? 'UNKNOWN',
      title: json['title'] ?? '',
      data: json['data'] ?? {},
    );
  }
}

class DashboardPayload {
  final String systemStatus;
  final String message;
  final List<DashboardWidget> widgets;
  final String? generatedAt;
  final String? runManifestRef;
  final Map<String, dynamic> marketSnapshot;

  DashboardPayload({
    required this.systemStatus,
    required this.message,
    required this.widgets,
    this.generatedAt,
    this.runManifestRef,
    required this.marketSnapshot,
  });

  factory DashboardPayload.fromJson(Map<String, dynamic> json) {
    var rawWidgets = json['widgets'] as List? ?? [];
    List<DashboardWidget> parsedWidgets = rawWidgets
        .map((w) => DashboardWidget.fromJson(w))
        .toList();

    return DashboardPayload(
      systemStatus: json['system_status'] ?? 'UNKNOWN',
      message: json['message'] ?? '',
      widgets: parsedWidgets,
      generatedAt: json['generated_at'],
      runManifestRef: json['run_manifest_ref'],
      marketSnapshot: json['market_snapshot'] ?? {},
    );
  }
}
