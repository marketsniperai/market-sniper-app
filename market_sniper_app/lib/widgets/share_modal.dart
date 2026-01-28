import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'mini_card_widget.dart';
import '../logic/share/share_exporter.dart';

class ShareModal extends StatefulWidget {
  final String ticker;
  final String timeframe;
  final String reliability;
  final String topBullet;

  const ShareModal({
    super.key,
    required this.ticker,
    required this.timeframe,
    required this.reliability,
    required this.topBullet,
  });

  @override
  State<ShareModal> createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isGenerating = false;

  Future<void> _handleShare() async {
    setState(() => _isGenerating = true);
    
    // Wait for frame to be stable
    await Future.delayed(const Duration(milliseconds: 100));
    
    final filename = 'ms_insight_${widget.ticker}_${DateTime.now().millisecondsSinceEpoch}.png';
    final path = await ShareExporter.captureAndSave(_captureKey, filename);
    
    setState(() => _isGenerating = false);
    
    if (path != null && mounted) {
      // Close modal before native sheet? Or keep open?
      // Better to keep open or close. Let's close to feel "Done".
      Navigator.pop(context); 
      ShareExporter.shareFile(context, path, text: "Institutional Insight on \$${widget.ticker} via MarketSniper AI.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.neonCyan, width: 1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Text(
                "SHARE INTEL",
                style: AppTypography.headline(context).copyWith(color: AppColors.neonCyan),
                textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
                "Generate a viral mini-card.",
                style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Preview Area (Center)
            Center(
                child: FittedBox(
                    child: RepaintBoundary(
                        key: _captureKey,
                        child: MiniCardWidget(
                            ticker: widget.ticker,
                            timeframe: widget.timeframe,
                            reliability: widget.reliability,
                            topBullet: widget.topBullet,
                        ),
                    ),
                ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
                onPressed: _isGenerating ? null : _handleShare,
                icon: _isGenerating 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.share, size: 18),
                label: Text(_isGenerating ? "GENERATING..." : "SHARE CARD"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface2,
                    foregroundColor: AppColors.neonCyan,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.neonCyan),
                ),
            )
        ],
      ),
    );
  }
}
