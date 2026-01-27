import 'package:flutter/material.dart';
import '../logic/standard_envelope.dart';
import '../domain/universe/core20_universe.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// D44.12: Read-only Context Strip for On-Demand results.
/// Displays available context (Sector, Regime, Overlay, Pulse) without recomputing.
class OnDemandContextStrip extends StatelessWidget {
  final StandardEnvelope envelope;
  final String ticker;

  const OnDemandContextStrip({
    super.key,
    required this.envelope,
    required this.ticker,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Extract Data
    final sector = _resolveSector();
    final regime = _resolveRegime();
    final overlay = _resolveOverlay();
    final pulse = _resolvePulse();

    // 2. Filter available
    final items = [
      if (sector != null) _ContextItem("SECTOR", sector, AppColors.textPrimary),
      if (regime != null)
        _ContextItem("REGIME", regime, _mapRegimeColor(regime)),
      if (overlay != null)
        _ContextItem("OVERLAY", overlay, _mapOverlayColor(overlay)),
      if (pulse != null) _ContextItem("PULSE", pulse, _mapPulseColor(pulse)),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    // 3. Render
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: items.map((item) => _buildChip(context, item)).toList(),
      ),
    );
  }

  Widget _buildChip(BuildContext context, _ContextItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${item.label}: ",
            style: AppTypography.label(context).copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold),
          ),
          Text(
            item.value,
            style: AppTypography.label(context).copyWith(
                fontSize: 10, color: item.color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- Resolution Logic ---

  String? _resolveSector() {
    // 1. Try CoreUniverse Lookup (Static)
    final def = CoreUniverse.getDefinition(ticker);
    if (def != null) {
      if (def.category == "Sectors") return def.displayLabel; // e.g. XLK
      return def.category; // e.g. Indices, Crypto
    }

    // 2. Try Payload
    final payload = envelope.rawPayload['payload'] ?? envelope.rawPayload;
    if (payload is Map && payload['sector'] != null) {
      return payload['sector'].toString().toUpperCase();
    }

    return null;
  }

  String? _resolveRegime() {
    // 1. Try Payload
    final payload = envelope.rawPayload['payload'] ?? envelope.rawPayload;
    if (payload is Map && payload['regime'] != null) {
      return payload['regime'].toString().toUpperCase();
    }
    return null;
  }

  String? _resolveOverlay() {
    // 1. Try Payload
    final payload = envelope.rawPayload['payload'] ?? envelope.rawPayload;
    if (payload is Map && payload['overlay'] != null) {
      return payload['overlay'].toString().toUpperCase();
    }
    // Also check 'overlay_status'
    if (payload is Map && payload['overlay_status'] != null) {
      return payload['overlay_status'].toString().toUpperCase();
    }
    return null;
  }

  String? _resolvePulse() {
    // 1. Try Payload (global_risk usually maps to Pulse state)
    final payload = envelope.rawPayload['payload'] ?? envelope.rawPayload;
    if (payload is Map && payload['global_risk'] != null) {
      return payload['global_risk'].toString().toUpperCase();
    }
    return null;
  }

  // --- Color Mapping ---

  Color _mapRegimeColor(String val) {
    if (val.contains("BULL")) return AppColors.stateLive;
    if (val.contains("BEAR")) return AppColors.stateLocked;
    return AppColors.textPrimary;
  }

  Color _mapOverlayColor(String val) {
    if (val.contains("LIVE")) return AppColors.stateLive;
    if (val.contains("SIM")) return AppColors.neonCyan;
    return AppColors.textDisabled;
  }

  Color _mapPulseColor(String val) {
    if (val.contains("RISK_ON")) return AppColors.stateLive;
    if (val.contains("RISK_OFF")) return AppColors.stateLocked;
    return AppColors.textPrimary;
  }
}

class _ContextItem {
  final String label;
  final String value;
  final Color color;
  _ContextItem(this.label, this.value, this.color);
}
