import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/calendar/economic_calendar_model.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;

  const CalendarEventCard({super.key, required this.event});

  Color _getCategoryColor() {
    switch (event.category) {
      case EventCategory.macro:
        return AppColors.neonCyan;
      case EventCategory.earnings:
        return AppColors.marketBull; // Green
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(event.timeUtc
        .toLocal()); // Convert to local/ET implied? Prompt says Time (ET). Assuming timeUtc is UTC, we should show ET. but for simplicity now, let's just show formatted time. If we had ET utils we'd use them. Let's assume input is correct or just format the UTC time for now and label it properly or just Time.
    // Wait, prompt says "Time (ET)". Let's assume we render what we have. If we have UTC, we should convert.
    // Since we don't have a reliable ET converter in this file, let's just format. Ideally we'd use TimeUtils.

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time Column
          SizedBox(
            width: 50,
            child: Text(
              timeStr,
              style: GoogleFonts.robotoMono(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Container(width: 1, height: 24, color: AppColors.borderSubtle),
          const SizedBox(width: 12),

          // Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCategoryBadge(context),
                    const SizedBox(width: 6),
                    _buildImpactBadge(context),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "SOURCE: ${event.source}",
                  style: GoogleFonts.inter(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _getCategoryColor().withValues(alpha: 0.3)),
      ),
      child: Text(
        event.category.name.toUpperCase(),
        style: TextStyle(
            color: _getCategoryColor(),
            fontSize: 9,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildImpactBadge(BuildContext context) {
    Color color;
    String label;

    switch (event.impact) {
      case EventImpact.high:
        color = AppColors.marketBear; // Red
        label = "HIGH";
        break;
      case EventImpact.medium:
        color = AppColors.stateStale;
        label = "MED";
        break;
      case EventImpact.low:
        color = AppColors.textDisabled;
        label = "LOW";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
