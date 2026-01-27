import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/news/news_digest_model.dart';
import '../../widgets/news_digest_card.dart';
import 'package:intl/intl.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // Simulating Source Ladder: OFFLINE for now as no pipeline is connected
  final NewsDigestViewModel _data = NewsDigestViewModel.offline();

  // Future: load from cache/pipeline

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _data.items.isEmpty
                  ? _buildDegradedState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _data.items.length,
                      itemBuilder: (context, index) {
                        return NewsDigestCard(item: _data.items[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final timeStr = DateFormat('HH:mm').format(_data.asOfUtc);
    Color freshnessColor;
    String freshnessLabel;

    switch (_data.freshness) {
      case DigestFreshness.live:
        freshnessColor = AppColors.stateLive;
        freshnessLabel = "LIVE";
        break;
      case DigestFreshness.delayed:
      case DigestFreshness.stale:
        freshnessColor = AppColors.stateStale;
        freshnessLabel = "DATA DELAYED";
        break;
      case DigestFreshness.offline:
      default:
        freshnessColor = AppColors.textDisabled;
        freshnessLabel = "OFFLINE";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DAILY DIGEST",
                style: AppTypography.title(context).copyWith(
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: freshnessColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border:
                      Border.all(color: freshnessColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  freshnessLabel,
                  style: TextStyle(
                      color: freshnessColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                "SOURCE: ${_data.source.name.toUpperCase()} • AS OF $timeStr UTC",
                style: GoogleFonts.robotoMono(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDegradedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox,
              size: 48, color: AppColors.textDisabled.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            "No digest available",
            style: GoogleFonts.inter(color: AppColors.textDisabled),
          ),
          if (_data.freshness == DigestFreshness.offline)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "System is offline",
                style: GoogleFonts.inter(
                    color: AppColors.textDisabled, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
