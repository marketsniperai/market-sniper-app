import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../config/app_config.dart';
import '../logic/premium_status_resolver.dart';
import '../logic/plus_unlock_engine.dart'; // D45.14
import '../models/premium/premium_matrix_model.dart'; // Verified import

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  bool _isElite = false;
  bool _isPlus = false;
  bool _isPlusUnlocked = false; // D45.14
  String _plusProgress = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    // Determine status (Sync now)
    final tier = PremiumStatusResolver.currentTier;
    
    // Founders get Elite access visually, but labeled
    final isFounder = AppConfig.isFounderBuild;
    
    // Map to local flags
    final isEliteValues = (tier == PremiumTier.elite || isFounder);
    final isPlusValues = (tier == PremiumTier.plus);

    bool unlocked = false;
    String progress = "";

    if (isPlusValues && !isEliteValues) {
       unlocked = await PlusUnlockEngine.isUnlocked();
       progress = await PlusUnlockEngine.getProgressString();
    }

    if (mounted) {
      setState(() {
         _isElite = isEliteValues;
         _isPlus = isPlusValues;
         _isPlusUnlocked = unlocked;
         _plusProgress = progress;
         _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
       return const Scaffold(
         backgroundColor: AppColors.bgDeepVoid,
         body: Center(child: CircularProgressIndicator(color: AppColors.accentCyan)),
       );
    }

    // Access Logic:
    // Elite/Founder -> Full
    // Plus (Unlocked) -> Full
    // Plus (Locked) -> Blurred + Progress
    // Free -> Locked/Hidden
    
    final bool hasAccess = _isElite || (_isPlus && _isPlusUnlocked);
    final bool showBlurred = _isPlus && !hasAccess;
    final bool locked = !_isElite && !_isPlus;

    return Scaffold(
      backgroundColor: AppColors.bgDeepVoid,
      appBar: AppBar(
        title: Text(
           AppConfig.isFounderBuild ? "COMMAND CENTER (FOUNDER VIEW)" : "COMMAND CENTER", 
           style: AppTypography.headline(context).copyWith(letterSpacing: 2.0)
        ),
        backgroundColor: AppColors.bgDeepVoid,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Content Layer (Always built, maybe blurred)
          if (!locked) 
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSectionHeader("CONTEXT SHIFTS (24H)"),
                   const SizedBox(height: 16),
                   _buildCard("Institutional Flow Reversal", ["Volume spike 14:00 ET", "Sector rotation: Tech -> Energy", "VIX divergence noted"]),
                   const SizedBox(height: 16),
                   _buildCard("Gamma Exposure Levels", ["GEX Flip pending at 4200", "Dealer positioning neutral"]),
                   const SizedBox(height: 32),
                   
                   _buildSectionHeader("HIGHEST CONFIDENCE DESCRIPTIONS"),
                   const SizedBox(height: 16),
                   _buildCard("Market State: FRACTURED", ["No clear trend dominance", "Risk: ELEVATED", "Action: PATIENCE"]),
                   const SizedBox(height: 32),

                   _buildSectionHeader("ARTIFACTS VAULT"),
                   const SizedBox(height: 16),
                   _buildArtifactRow("Briefing.json", "d45_briefing_latest"),
                   _buildArtifactRow("PulseState.log", "d45_pulse_snapshot"),
                   _buildArtifactRow("OneRule.md", "canon_rule_01"),
                ],
              ),
            ),
            
          // Blur Layer for Plus
          if (showBlurred)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: AppColors.bgDeepVoid.withValues(alpha: 0.6),
                    child: Center(
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                            const Icon(Icons.lock, color: AppColors.stateLocked, size: 48),
                            const SizedBox(height: 16),
                            Text("ELITE CLEARANCE REQUIRED", style: AppTypography.headline(context).copyWith(color: AppColors.stateLocked)),
                            const SizedBox(height: 8),
                            Text("Command Center access is restricted.", style: AppTypography.body(context)),
                            const SizedBox(height: 16),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 color: AppColors.surface1,
                                 borderRadius: BorderRadius.circular(4),
                                 border: Border.all(color: AppColors.accentCyan),
                               ),
                               child: Text("PLUS PROGRESS: $_plusProgress", style: const TextStyle(color: AppColors.accentCyan, fontSize: 11, fontFamily: 'RobotoMono', fontWeight: FontWeight.bold)),
                            )
                         ],
                       ),
                    ),
                  ),
                ),
              ),
            ),
            
          // Locked Layer for Free/Guest
          if (locked)
             Center(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    const Icon(Icons.visibility_off, color: AppColors.textDisabled, size: 48),
                    const SizedBox(height: 16),
                    Text("NO SIGNAL", style: AppTypography.headline(context).copyWith(color: AppColors.textDisabled)),
                 ],
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.accentCyan, fontSize: 10, letterSpacing: 1.5, fontFamily: 'RobotoMono', fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(height: 1, color: AppColors.accentCyan.withValues(alpha: 0.3)),
      ],
    );
  }

  Widget _buildCard(String title, List<String> bullets) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono')),
          const SizedBox(height: 12),
          ...bullets.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text(">", style: TextStyle(color: AppColors.accentCyan, fontSize: 10, fontFamily: 'RobotoMono')),
                 const SizedBox(width: 8),
                 Expanded(child: Text(b, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'RobotoMono'))),
               ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildArtifactRow(String name, String hash) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
           const Icon(Icons.description, color: AppColors.textDisabled, size: 16),
           const SizedBox(width: 8),
           Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'RobotoMono')),
           const Spacer(),
           Text(hash, style: const TextStyle(color: AppColors.textDisabled, fontSize: 10, fontFamily: 'RobotoMono')),
        ],
      ),
    );
  }
}
