import 'package:flutter/material.dart';
import '../logic/recent_dossier_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class RecentDossierRail extends StatelessWidget {
  final List<RecentDossierEntry> entries;
  final Function(RecentDossierEntry) onTap;

  const RecentDossierRail({
    super.key,
    required this.entries,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "RECENT DOSSIERS",
            style: AppTypography.label(context).copyWith(
              color: AppColors.textDisabled,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCard(context, entry),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, RecentDossierEntry entry) {
    // Age string
    final storedTime = DateTime.parse(entry.timestampUtc).toLocal();
    final diff = DateTime.now().difference(storedTime);
    String age = "";
    if (diff.inMinutes < 60) {
      age = "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      age = "${diff.inHours}h ago";
    } else {
      age = "${diff.inDays}d ago";
    }

    // Reliability Color
    Color relColor = AppColors.textDisabled;
    if (entry.reliabilityState == "HIGH") relColor = AppColors.stateLive;
    if (entry.reliabilityState == "MED") relColor = AppColors.stateStale;
    if (entry.reliabilityState == "LOW") relColor = AppColors.marketBear;
    if (entry.reliabilityState == "CALIBRATING") relColor = AppColors.neonCyan;

    return GestureDetector(
      onTap: () => onTap(entry),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
             BoxShadow(
                       color: Colors.black.withValues(alpha: 0.2),
               blurRadius: 4,
               offset: const Offset(0, 2)
             )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.ticker,
                  style: AppTypography.body(context).copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                   decoration: BoxDecoration(
                     color: AppColors.surface2, // Fixed: surface3 not defined
                     borderRadius: BorderRadius.circular(2)
                   ),
                   child: Text(
                     entry.timeframe.substring(0, 1), // "D" or "W"
                     style: AppTypography.caption(context).copyWith(
                       color: AppColors.textSecondary,
                       fontSize: 8, 
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                )
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: relColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  entry.reliabilityState,
                  style: AppTypography.caption(context).copyWith(
                      color: relColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold
                  ),
                )
              ],
            ),
             const SizedBox(height: 4),
             Text(
               age,
               style: AppTypography.label(context).copyWith(fontSize: 8, color: AppColors.textDisabled),
             )
          ],
        ),
      ),
    );
  }
}
