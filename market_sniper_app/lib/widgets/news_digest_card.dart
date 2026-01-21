import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/news/news_digest_model.dart';
import 'package:intl/intl.dart';

class NewsDigestCard extends StatefulWidget {
  final NewsDigestItem item;

  const NewsDigestCard({super.key, required this.item});

  @override
  State<NewsDigestCard> createState() => _NewsDigestCardState();
}

class _NewsDigestCardState extends State<NewsDigestCard> with SingleTickerProviderStateMixin {
  bool _isFlipped = false;

  void _toggleFlip() {
    setState(() => _isFlipped = !_isFlipped);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: 3.14, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, child) {
              final isUnder = (ValueKey(_isFlipped) != child!.key);
              var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
              tilt *= isUnder ? -1.0 : 1.0;
              final value = isUnder ? 3.14 * animation.value : 3.14 * (1 - animation.value); // Simplified crossfade effect fallback if rotation is too complex for now, but trying simple switcher first.
              // Actually, standard crossfade is safer for layout.
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
        child: _isFlipped ? _buildBack(context) : _buildFront(context),
      ),
    );
  }

  Widget _buildFront(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(widget.item.publishedUtc);
    
    return Container(
      key: const ValueKey(false),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.item.title,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.touch_app, size: 14, color: AppColors.accentCyan.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                "${widget.item.source} • $timeStr UTC",
                style: GoogleFonts.robotoMono(
                  color: AppColors.textDisabled, 
                  fontSize: 10
                ),
              ),
              if (widget.item.impact == DigestImpact.high) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.marketBear.withValues(alpha: 0.2), // Red for impact
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text("HIGH IMPACT", style: TextStyle(color: AppColors.marketBear, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.item.summaryBrief,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(widget.item.publishedUtc);

    return Container(
      key: const ValueKey(true),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)), // Active border
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: AppColors.glowCyan, blurRadius: 4, spreadRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.title,
            style: GoogleFonts.inter(
              color: AppColors.accentCyan, // Highlight
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                "${widget.item.source} • $timeStr UTC",
                style: GoogleFonts.robotoMono(
                  color: AppColors.textDisabled, 
                  fontSize: 10
                ),
              ),
              const Spacer(),
              Text(
                "Tap to flip back",
                style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 9, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          const Divider(color: AppColors.borderSubtle, height: 16),
          Text(
            widget.item.summaryExpand,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
