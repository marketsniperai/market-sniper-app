import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../config/app_config.dart';
import '../logic/premium_status_resolver.dart';
import '../logic/plus_unlock_engine.dart'; // D45.14
import '../logic/command_center/command_center_builder.dart'; // D45.15
import '../logic/share/viral_teaser_store.dart'; // D45.16
import '../logic/share/teaser_composer.dart'; // D45.16
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
  
  CommandCenterData? _data; // D45.15
  bool _isLoading = true;
  bool _showTeaserBanner = false; // D45.16

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadData();
    _checkTeaser();
  }

  Future<void> _checkTeaser() async {
     final seen = await ViralTeaserStore.isFirstOpenSeen();
     // Or maybe we want to show it until they dismiss/share? 
     // "trigger: first_open_of_command_center" implies ONCE.
     // Let's show it if NOT seen.
     if (!seen && mounted) {
        setState(() => _showTeaserBanner = true);
        // Mark seen *after* they see it? Or immediately?
        // Prompt doesn't specify persistence of the banner itself, just the trigger.
        // Usually "First Open" means we detect it's the first time.
        // If we want them to act on it, maybe don't mark seen until dismissed?
        // Simpler: Mark seen after this session.
        await ViralTeaserStore.markFirstOpenSeen();
     }
  }

  Future<void> _loadData() async {
    final data = await CommandCenterBuilder.build();
    if (mounted) {
       setState(() {
         _data = data;
       });
    }
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
         // _isLoading = false; // Wait for data
      });
      // Data load finishes separately and clears loading if we want, 
      // or we can clear here if we don't block on data. 
      // Let's block on data for the content part?
      // Actually, isLoading currently blocks entire screen.
      // Let's modify build method to Handle partial stats.
      setState(() => _isLoading = false);
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
          if (!locked && _data != null) 
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (_showTeaserBanner)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentCyan.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.accentCyan),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                             const Icon(Icons.share, color: AppColors.accentCyan, size: 20),
                             const SizedBox(width: 12),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text("You just opened a hidden OS surface.", style: AppTypography.body(context).copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                                   const SizedBox(height: 4),
                                   GestureDetector(
                                     onTap: () async {
                                        // Share Action
                                        await TeaserComposer.shareTeaser(isFounder: AppConfig.isFounderBuild);
                                        await ViralTeaserStore.markShared();
                                        if (mounted) setState(() => _showTeaserBanner = false);
                                     },
                                     child: Text("SHARE A TEASER >", style: AppTypography.label(context).copyWith(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                                   ),
                                 ],
                               ),
                             ),
                             IconButton(
                               icon: const Icon(Icons.close, color: AppColors.textDisabled, size: 16),
                               onPressed: () => setState(() => _showTeaserBanner = false),
                             )
                          ],
                        ),
                      ),
                   
                   _buildSectionHeader("CONTEXT SHIFTS (24H)"),
                   const SizedBox(height: 16),
                   ..._data!.contextShifts.map((c) => Column(
                     children: [
                       _buildCard(c.title, c.bullets, badges: c.badges),
                       const SizedBox(height: 16),
                     ],
                   )),
                   const SizedBox(height: 16),
                   
                   _buildSectionHeader("HIGHEST CONFIDENCE DESCRIPTIONS"),
                   const SizedBox(height: 16),
                   ..._data!.confidenceDescriptions.map((c) => Column(
                     children: [
                        _buildCard(c.title, c.bullets, badges: c.badges),
                        const SizedBox(height: 16),
                     ],
                   )),
                   const SizedBox(height: 32),

                   _buildSectionHeader("THE OS LEARNED THIS WEEK"),
                   const SizedBox(height: 16),
                   ..._data!.learnings.map((l) => Padding(
                     padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                     child: Text("• $l", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'RobotoMono')),
                   )),
                   const SizedBox(height: 32),

                   _buildSectionHeader("ARTIFACTS VAULT"),
                   const SizedBox(height: 16),
                   ..._data!.artifacts.map((a) => _buildArtifactRow(a['name']!, a['status']!)),
                   
                   const SizedBox(height: 32),
                   const Divider(color: AppColors.borderSubtle),
                   const SizedBox(height: 8),
                   const Text(
                     "Descriptive context snapshot — not a forecast.",
                     style: TextStyle(color: AppColors.textDisabled, fontSize: 10, fontStyle: FontStyle.italic),
                   ),
                   const SizedBox(height: 32),
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

  Widget _buildCard(String title, List<String> bullets, {List<String> badges = const []}) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono'))),
               if (badges.isNotEmpty)
                  ...badges.map((b) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.accentCyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)),
                      child: Text(b, style: const TextStyle(color: AppColors.accentCyan, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ))
            ],
          ),
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
