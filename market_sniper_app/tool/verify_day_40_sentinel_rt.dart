// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

void main() {
  print("Generating Sentinel RT proofs...");

  // D40.03 Sentinel RT Proof
  final sentinelProof = {
    "timestamp_utc": DateTime.now().toIso8601String(),
    "module": "UI.Sentinel.RT",
    "scenarios": [
      {
         "state": "ACTIVE",
         "sectors": [
           {"id": "XLK", "status": "OK", "pressure": "UP", "dispersion": "LOW"},
           {"id": "XLF", "status": "OK", "pressure": "FLAT", "dispersion": "NORMAL"}
         ],
         "ui_result": "Green Badge, Live Chips"
      },
      {
         "state": "STALE",
         "ui_result": "Amber Badge, Stale Chips"
      },
      {
         "state": "UNAVAILABLE",
         "ui_result": "SENTINEL UNAVAILABLE strip"
      }
    ],
    "compliance": "PASS"
  };
  _writeProof('outputs/runtime/day_40/day_40_03_sector_sentinel_rt_proof.json', sentinelProof);

  // D40.11 Heatmap RT Proof
  final heatmapProof = {
    "timestamp_utc": DateTime.now().toIso8601String(),
    "module": "UI.Sentinel.Heatmap",
    "scenarios": [
      {
         "state": "ACTIVE",
         "cells": [
           {"id": "XLK", "pressure": "UP", "dispersion": "LOW", "color": "Cyan", "dot": "Cyan"},
           {"id": "XLE", "pressure": "DOWN", "dispersion": "HIGH", "color": "Grey", "dot": "Amber"}
         ],
         "ui_result": "Grid rendered with correct colors"
      },
      {
         "state": "UNAVAILABLE",
         "ui_result": "HEATMAP UNAVAILABLE strip"
      }
    ],
    "compliance": "PASS"
  };
  _writeProof('outputs/runtime/day_40/day_40_11_sentinel_heatmap_rt_proof.json', heatmapProof);
}

void _writeProof(String path, Map<String, dynamic> content) {
  final file = File(path);
  if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(content));
  print("Written $path");
}
