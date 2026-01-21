import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/premium/premium_matrix_model.dart';
import '../../logic/premium_status_resolver.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  List<PremiumFeatureRow> _rows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatrix();
  }

  Future<void> _loadMatrix() async {
    // In production this would read SSOT from assets
    final rows = await PremiumMatrixModel.load();
    if (mounted) {
      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current Tier Logic
    final currentTier = PremiumStatusResolver.currentTier;
    
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text("PREMIUM PROTOCOL", style: AppTypography.title(context)),
        centerTitle: true,
        leading: const CloseButton(color: AppColors.textPrimary),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   _buildCurrentTierBanner(context, currentTier),
                   const SizedBox(height: 24),
                   _buildMatrixHeader(),
                   const SizedBox(height: 8),
                   ..._rows.map((row) => _buildMatrixRow(context, row, currentTier)),
                   const SizedBox(height: 32),
                   _buildFooterCta(context, currentTier),
                   const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentTierBanner(BuildContext context, PremiumTier currentTier) {
    Color tierColor;
    String tierLabel;

    switch (currentTier) {
      case PremiumTier.guest:
        tierColor = AppColors.textDisabled;
        tierLabel = "GUEST";
        break;
      case PremiumTier.plus:
        tierColor = AppColors.accentCyan;
        tierLabel = "PLUS";
        break;
      case PremiumTier.elite:
        tierColor = AppColors.marketBull;
        tierLabel = "ELITE";
        break;
      case PremiumTier.founder:
        tierColor = AppColors.stateLive; // Special
        tierLabel = "FOUNDER";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            "CURRENT STATUS",
            style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 10, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Text(
            tierLabel,
            style: AppTypography.headline(context).copyWith(color: tierColor),
          ),
          if (currentTier == PremiumTier.founder)
             Padding(
               padding: const EdgeInsets.only(top: 4.0),
               child: Text(
                 "ALWAYS-ON ENABLED",
                 style: GoogleFonts.robotoMono(color: AppColors.stateLive, fontSize: 10),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildMatrixHeader() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text("FEATURE", style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        _buildHeaderCell("GUEST"),
        _buildHeaderCell("PLUS"),
        _buildHeaderCell("ELITE"),
        _buildHeaderCell("FOUNDER"),
      ],
    );
  }

  Widget _buildHeaderCell(String label) {
    return Expanded(
      flex: 2,
      child: Center(
        child: Text(
          label[0], // First letter only on mobile to save space, or rotate? 
          // Matrix grid on phone is tight. Let's try 1 letter or specific icon.
          // Prompt says "4 tiers". Let's assume standard phone width.
          style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMatrixRow(BuildContext context, PremiumFeatureRow row, PremiumTier currentTier) {
    // Dynamic Label Substitution
    String label = row.label;
    if (row.dynamicValueKey == "trial_opens_progress") {
       label = label.replaceFirst("Trial", "Trial: ${PremiumStatusResolver.trialProgressString}");
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(row.detail, style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          _buildStatusCell(row.availability[PremiumTier.guest], row.limits[PremiumTier.guest], row.key == "trial_progress"),
          _buildStatusCell(row.availability[PremiumTier.plus], row.limits[PremiumTier.plus], row.key == "trial_progress"),
          _buildStatusCell(row.availability[PremiumTier.elite], row.limits[PremiumTier.elite], row.key == "trial_progress"),
          _buildStatusCell(row.availability[PremiumTier.founder], row.limits[PremiumTier.founder], row.key == "trial_progress"),
        ],
      ),
    );
  }

  Widget _buildStatusCell(FeatureStatus? status, String? limit, bool isTrialRow) {
    Widget icon;
    switch (status) {
      case FeatureStatus.included:
        if (isTrialRow) {
           // Special icon for Trial row? Or just checkmark. Prompt implies 0/3 logic.
           // Actually, if it's "Trial (0/3 Market Opens)", the row itself explains it.
           // The status is just "Included".
        }
        icon = const Icon(Icons.check, color: AppColors.stateLive, size: 14);
        break;
      case FeatureStatus.locked:
        icon = const Icon(Icons.lock, color: AppColors.textDisabled, size: 12);
        break;
      case FeatureStatus.limited:
        icon = const Icon(Icons.timelapse, color: AppColors.accentCyan, size: 14);
        break;
      case FeatureStatus.progress:
        icon = const Icon(Icons.trending_up, color: AppColors.marketBull, size: 14);
        break;
      default:
        icon = const SizedBox();
    }

    return Expanded(
      flex: 2,
      child: Column(
        children: [
          icon,
          if (limit != null && status != FeatureStatus.locked) // Show limit if relevant
             Padding(
               padding: const EdgeInsets.only(top: 2.0),
               child: Text(
                 "Limit", // Too tight for full text
                 style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 7),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildFooterCta(BuildContext context, PremiumTier tier) {
     String label;
     VoidCallback? onTap;

     switch (tier) {
       case PremiumTier.guest:
         label = "Try-Me Hour Info";
         onTap = () {}; // No-op proof
         break;
       case PremiumTier.plus:
         label = "Unlock Elite";
         onTap = () {};
         break;
       case PremiumTier.elite:
         label = "You are Elite";
         onTap = null;
         break;
       case PremiumTier.founder:
         label = "Founder Always-On";
         onTap = null;
         break;
     }

     if (onTap == null) {
       return Center(
         child: Text(label, style: GoogleFonts.inter(color: AppColors.textDisabled)),
       );
     }

     return ElevatedButton(
       onPressed: onTap,
       style: ElevatedButton.styleFrom(
         backgroundColor: AppColors.accentCyan.withValues(alpha: 0.1),
         foregroundColor: AppColors.accentCyan,
         side: const BorderSide(color: AppColors.accentCyan),
       ),
       child: Text(label),
     );
  }
}
