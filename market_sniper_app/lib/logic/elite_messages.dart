import 'package:flutter/material.dart';

class EliteExplainNotification extends Notification {
  final String explainKey;
  final Map<String, dynamic>? payload;

  const EliteExplainNotification(this.explainKey, {this.payload});
}
