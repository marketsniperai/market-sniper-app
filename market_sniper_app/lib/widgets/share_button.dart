import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../logic/share/share_exporter.dart';

class ShareButton extends StatefulWidget {
  final GlobalKey repaintBoundaryKey;
  final String contentTitle;

  const ShareButton({
    super.key,
    required this.repaintBoundaryKey,
    required this.contentTitle,
  });

  @override
  State<ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<ShareButton> {
  bool _isExporting = false;

  Future<void> _handleShare() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    // Give UI a moment to be sure everything is painted if needed?
    // Actually RepaintBoundary captures what's there.
    
    final filename = "msr_share_${DateTime.now().millisecondsSinceEpoch}.png";
    final path = await ShareExporter.captureAndSave(widget.repaintBoundaryKey, filename);
    
    if (path != null) {
       await ShareExporter.shareFile(context, path, text: widget.contentTitle);
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Snapshot Generated for Sharing"), duration: Duration(seconds: 1))
          );
       }
    } else {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Export Failed"))
          );
       }
    }

    if (mounted) setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isExporting 
        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentCyan))
        : const Icon(Icons.share, color: AppColors.accentCyan, size: 20),
      tooltip: "Share Snippet",
      onPressed: _handleShare,
    );
  }
}
