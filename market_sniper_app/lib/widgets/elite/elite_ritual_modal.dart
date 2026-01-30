
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'dart:ui' as ui;

class EliteRitualModal extends StatelessWidget {
  final String title;
  final Map<String, dynamic> payload; // This is now the ENVELOPE

  const EliteRitualModal({
    super.key,
    required this.title,
    required this.payload,
  });

  @override
  Widget build(BuildContext context) {
    // D49.HF01: Parse Envelope
    final String status = payload['status'] ?? "UNKNOWN";
    final data = payload['payload']; // dynamic
    final Map<String, dynamic> meta = (data != null && data is Map) ? (data['meta'] ?? {}) : {};
    
    final String timestamp = payload['as_of_utc'] ?? meta['asOfUtc'] ?? "Unknown Time";
    final String source = meta['source'] ?? "Unknown Source";

    final bool isOK = status == 'OK' && data != null;
    final List sections = (isOK && data is Map) ? (data['sections'] ?? []) : [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Sheet height
      decoration: BoxDecoration(
         color: AppColors.surface1,
         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
         border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withValues(alpha: 0.5),
             blurRadius: 20,
             spreadRadius: 5,
           )
         ]
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
           filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
           child: Column(
             children: [
               // Header
               _buildHeader(context, timestamp, isOK ? source : status),
               
               // Divider
               Divider(color: AppColors.neonCyan.withValues(alpha: 0.2), height: 1),
               
               // Body
               Expanded(
                 child: isOK 
                  ? _buildContent(context, sections)
                  : _buildFallback(context, status, payload['details']),
               ),
               
               // Footer / Close
               Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.surface2,
                       foregroundColor: AppColors.textPrimary,
                       side: const BorderSide(color: AppColors.borderSubtle),
                       padding: const EdgeInsets.symmetric(vertical: 16),
                     ),
                     onPressed: () => Navigator.of(context).pop(),
                     child: Text("DISMISS", style: AppTypography.label(context)),
                   ),
                 ),
               )
             ],
           ),
        ),
      ),
    );
  }
  
  // Re-uses _buildHeader logic but updated
  Widget _buildHeader(BuildContext context, String timestamp, String badge) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text(title.toUpperCase(), 
                    style: AppTypography.headline(context).copyWith(
                      color: AppColors.neonCyan, fontSize: 18
                    )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(badge.toUpperCase(),
                      style: AppTypography.caption(context).copyWith(
                        color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold
                      )
                  ),
                )
             ],
           ),
           const SizedBox(height: 8),
           Text("AS OF: $timestamp", style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary)),
         ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, List sections) {
     return ListView.builder(
       padding: const EdgeInsets.all(24),
       itemCount: sections.length,
       itemBuilder: (context, index) {
         final section = sections[index];
         return _buildSection(context, section);
       },
     );
  }
  
  Widget _buildFallback(BuildContext context, String status, String? details) {
      IconData icon = Icons.info_outline;
      String message = "Ritual data is currently unavailable.";
      Color color = AppColors.textSecondary;
      
      if (status == 'WINDOW_CLOSED') {
          icon = Icons.lock_clock;
          message = "This ritual window is closed. Please return at the scheduled time.";
          color = AppColors.stateLocked;
      } else if (status == 'CALIBRATING') {
          icon = Icons.build_circle_outlined;
          message = "Ritual Engine is calibrating... Check back in a few minutes.";
          color = AppColors.neonCyan;
      } else if (status == 'OFFLINE') {
          icon = Icons.wifi_off;
          message = "System offline.";
      }
      
      return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(icon, size: 48, color: color.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(status, style: AppTypography.headline(context).copyWith(color: color)),
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center, style: AppTypography.body(context).copyWith(color: AppColors.textSecondary)),
                    if (details != null)
                       Padding(
                         padding: const EdgeInsets.only(top: 16.0),
                         child: Text("Debug: $details", style: const TextStyle(fontSize: 10, color: AppColors.textDisabled)),
                       )
                ],
            ),
          ),
      );
  }

  Widget _buildSection(BuildContext context, Map<String, dynamic> section) {
    final String type = section['type'] ?? 'text';
    final String title = section['title'] ?? 'Section';
    final dynamic content = section['content'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(title.toUpperCase(),
               style: AppTypography.label(context).copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold, letterSpacing: 1.1)
           ),
           const SizedBox(height: 8),
           _renderContent(context, type, content),
        ],
      ),
    );
  }

  Widget _renderContent(BuildContext context, String type, dynamic content) {
    final style = AppTypography.body(context).copyWith(height: 1.5, color: AppColors.textSecondary);

    if (type == 'list' && content is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content.map<Widget>((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("• ", style: TextStyle(color: AppColors.neonCyan)),
              Expanded(child: Text(item.toString(), style: style)),
            ],
          ),
        )).toList(),
      );
    } else if (type == 'key_value' && content is Map) {
       return Column(
         children: content.entries.map<Widget>((e) => Padding(
           padding: const EdgeInsets.only(bottom: 4.0),
           child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Text(e.key.toString(), style: style.copyWith(fontWeight: FontWeight.bold)),
                Text(e.value.toString(), style: style),
             ],
           ),
         )).toList(),
       );
    }

    // Default Text
    return Text(content.toString(), style: style);
  }
}
