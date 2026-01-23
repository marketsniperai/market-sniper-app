
import 'package:flutter/material.dart';
import 'package:market_sniper_app/theme/app_colors.dart';
import 'package:market_sniper_app/widgets/atoms/status_chip.dart';
import 'package:market_sniper_app/widgets/atoms/glass_card.dart';

/// D36.3: Options Context Widget (Options Intelligence v1).
/// Displays safe, descriptive options data (IV Regime, Skew, Expected Move).
/// Handles N/A states gracefully without panic UI.
class OptionsContextWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const OptionsContextWidget({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Safe N/A Logic (Default to N/A if missing)
    final String status = data['status'] ?? 'N_A';
    final String coverage = data['coverage'] ?? 'N_A';
    final String ivRegime = data['iv_regime'] ?? 'N/A';
    final String skew = data['skew'] ?? 'N/A';
    final String expectedMove = data['expected_move'] ?? 'N/A';
    final String? notes = data['notes'];

    // 2. Status Color Logic
    Color statusColor = AppColors.textDim;
    if (status == 'LIVE') statusColor = AppColors.primary;
    if (status == 'PROVIDER_DENIED') statusColor = AppColors.cautious;
    if (status == 'PROXY_ESTIMATED') statusColor = AppColors.cautious;
    // N_A stays textDim

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title + Status Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 14, color: AppColors.textDim),
                    SizedBox(width: 6),
                    Text(
                      'OPTIONS INTELLIGENCE',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (coverage != 'N_A' && coverage != 'FULL')
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: StatusChip(
                          label: coverage,
                          color: AppColors.textDim,
                          isOutline: true,
                        ),
                      ),
                    StatusChip(
                      label: status,
                      color: statusColor,
                      isOutline: status != 'LIVE', // Solid only if LIVE
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),

            // Data Grid (3 Columns)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricColumn('IV REGIME', ivRegime),
                _buildMetricColumn('SKEW', skew),
                _buildMetricColumn('EXP. MOVE', expectedMove),
              ],
            ),

            // Optional Note (if present and meaningful)
            if (notes != null && notes.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLayer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderFaint),
                ),
                child: Text(
                  notes,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    // Mute value if N/A
    final bool isNA = value == 'N/A';
    
    // v1.1.0: Add tiny indicator if value is EST/PROXY? For now, standard text.
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isNA ? AppColors.textDim : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }
}
