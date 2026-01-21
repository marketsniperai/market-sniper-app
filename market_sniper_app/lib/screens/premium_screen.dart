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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text("FEATURE", style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ),
          _buildHeaderCell("GUEST", AppColors.textDisabled),
          _buildHeaderCell("PLUS", AppColors.accentCyan),
          _buildHeaderCell("ELITE", AppColors.marketBull),
          _buildHeaderCell("FNDR", AppColors.stateLive, isFounder: true), // Abbreviated for space
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, Color color, {bool isFounder = false}) {
    return Expanded(
      flex: 2,
      child: Container(
        alignment: Alignment.center,
        color: isFounder ? AppColors.stateLive.withValues(alpha: 0.05) : Colors.transparent,
        child: Text(
          label,
          style: GoogleFonts.inter(color: color, fontSize: 9, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMatrixRow(BuildContext context, PremiumFeatureRow row, PremiumTier currentTier) {
    // Dynamic Label
    String label = row.label;
    if (row.dynamicValueKey == "trial_opens_progress") {
       label = "Trial (${PremiumStatusResolver.trialProgressString} Opens)";
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle.withValues(alpha: 0.3))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Label Column
            Expanded(
              flex: 4,
              child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                     const SizedBox(height: 2),
                     Text(row.detail, style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 9, height: 1.1), maxLines: 2, overflow: TextOverflow.ellipsis),
                   ],
                 ),
              ),
            ),
            // Status Columns (Vertical Dividers?)
            _buildStatusCell(row.availability[PremiumTier.guest], row.limits[PremiumTier.guest], false),
            _buildStatusCell(row.availability[PremiumTier.plus], row.limits[PremiumTier.plus], false),
            _buildStatusCell(row.availability[PremiumTier.elite], row.limits[PremiumTier.elite], false),
            _buildStatusCell(row.availability[PremiumTier.founder], row.limits[PremiumTier.founder], true, isFounder: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCell(FeatureStatus? status, String? limit, bool isTrialRow, {bool isFounder = false}) {
    Color bg = isFounder ? AppColors.stateLive.withValues(alpha: 0.05) : Colors.transparent;
    
    // Status Chip Logic
    Widget chip;
    switch (status) {
      case FeatureStatus.included:
        chip = const Icon(Icons.check, color: AppColors.stateLive, size: 14);
        break;
      case FeatureStatus.locked:
        chip = const Icon(Icons.lock_outline, color: AppColors.textDisabled, size: 12);
        break;
      case FeatureStatus.limited:
        chip = Text("LIMIT", style: GoogleFonts.robotoMono(color: AppColors.accentCyan, fontSize: 8, fontWeight: FontWeight.bold));
        break;
      case FeatureStatus.progress:
        chip = const Icon(Icons.trending_up, color: AppColors.marketBull, size: 14);
        break;
      default:
        chip = const SizedBox();
    }

    return Expanded(
      flex: 2,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
               width: 24, height: 24,
               alignment: Alignment.center,
               decoration: BoxDecoration(
                 color: AppColors.surface1,
                 shape: BoxShape.circle,
                 border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
               ),
               child: chip,
            ),
            if (limit != null && status != FeatureStatus.locked)
               Padding(
                 padding: const EdgeInsets.only(top: 4.0),
                 child: Text(
                   limit, 
                   style: GoogleFonts.inter(color: AppColors.textDisabled, fontSize: 8),
                   textAlign: TextAlign.center,
                 ),
               ),
          ],
        ),
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
