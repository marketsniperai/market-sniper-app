import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../logic/share/share_library_store.dart';
import '../logic/share/caption_presets.dart';
import '../logic/share/share_exporter.dart'; // Reuse exporter

class ShareLibraryScreen extends StatefulWidget {
  const ShareLibraryScreen({super.key});

  @override
  State<ShareLibraryScreen> createState() => _ShareLibraryScreenState();
}

class _ShareLibraryScreenState extends State<ShareLibraryScreen> {
  List<ShareItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await ShareLibraryStore.getHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleReshare(ShareItem item) async {
    // Log Re-share attempt (or CTA open if we consider this an interaction)
    // For now getting the file again might be tricky if cleaned up.
    // If localPath exists and file exists, share it.
    if (item.localPath != null) {
       await ShareExporter.shareFile(item.localPath!, text: CaptionPresets.all[item.captionKey] ?? "");
       await ShareLibraryStore.logEvent('SHARE_RESHARE', {'hash': item.contentHash});
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File expired.")));
    }
  }

  Future<void> _handleUpgradeCta() async {
    await ShareLibraryStore.logEvent('CTA_UPGRADE_CLICKED', {'source': 'library_footer'});
    // Mock Nav
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Premium Upgrade...")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface1,
      appBar: AppBar(
        title: Text("SHARE HISTORY", style: AppTypography.headline(context).copyWith(fontSize: 16)),
        backgroundColor: AppColors.surface1,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner / CTA
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             color: AppColors.surface2,
             child: Row(
               children: [
                 const Icon(Icons.star, color: AppColors.accentCyan, size: 20),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text("Unlock Elite Sharing", style: AppTypography.label(context).copyWith(color: AppColors.textPrimary)),
                        Text("Remove watermarks & export high-res.", style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary)),
                     ],
                   ),
                 ),
                 TextButton(
                    onPressed: _handleUpgradeCta,
                    child: Text("UPGRADE", style: AppTypography.label(context).copyWith(color: AppColors.accentCyan)),
                 )
               ],
             ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
              : _history.isEmpty 
                  ? Center(child: Text("No shares yet.", style: AppTypography.body(context).copyWith(color: AppColors.textDisabled)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                         final item = _history[index];
                         return _buildHistoryItem(context, item);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, ShareItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
           Container(
             width: 48, 
             height: 48,
             color: AppColors.surface2,
             child: const Icon(Icons.image, color: AppColors.textDisabled, size: 24),
           ),
           const SizedBox(width: 12),
           Expanded(
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(item.timestamp, style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary)),
                   const SizedBox(height: 4),
                   Text(item.captionKey, style: AppTypography.label(context).copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                ],
             ),
           ),
           IconButton(
             icon: const Icon(Icons.share, color: AppColors.accentCyan, size: 20),
             onPressed: () => _handleReshare(item),
           )
        ],
      ),
    );
  }
}
