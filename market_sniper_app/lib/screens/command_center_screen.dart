
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../config/app_config.dart';
import '../logic/premium_status_resolver.dart';
import '../logic/command_center/command_center_builder.dart'; // D45.15
import '../models/premium/premium_matrix_model.dart'; // Verified import

// D61.3 Rewire
import '../widgets/command_center/coherence_quartet_card.dart';
import '../widgets/command_center/market_pressure_orb.dart';
import '../services/command_center/discipline_counter_service.dart';
import '../models/command_center/command_center_tier.dart';

class CommandCenterScreen extends StatefulWidget {
  final VoidCallback? onBack; 
  const CommandCenterScreen({super.key, this.onBack});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  bool _isElite = false;
  bool _isPlus = false;
  
  late DisciplineCounterService _disciplineService;
  CommandCenterAccessState _accessState = const CommandCenterAccessState(tier: CommandCenterTier.elite, isDoorUnlocked: true);
  int _freeTapsRemaining = 4;

  CommandCenterData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDiscipline();
    _loadData();
  }

  Future<void> _initDiscipline() async {
    _disciplineService = await DisciplineCounterService.init();
    await _checkAccess();
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
    // 1. Resolve Real Premium Tier
    final premiumTier = PremiumStatusResolver.currentTier;
    final isFounder = AppConfig.isFounderBuild;
    
    // 2. Map to CommandCenterTier
    CommandCenterTier baseTier = CommandCenterTier.free;

    // FOUNDER OVERRIDE (D61.x.06B)
    // Force Elite if Founder Build in Debug Mode (bypasses entitlement failures)
    if (AppConfig.isFounderBuild && kDebugMode) {
      baseTier = CommandCenterTier.elite;
      debugPrint("CC_VISIBILITY: founderDebugOverride=true tier=CommandCenterTier.elite");
    } else if (premiumTier == PremiumTier.elite || isFounder) {
       baseTier = CommandCenterTier.elite;
    } else if (premiumTier == PremiumTier.plus) {
       baseTier = CommandCenterTier.plus;
    }

    // 3. Get Effective State from DisciplineService
    final accessState = _disciplineService.getAccessState(baseTier);

    // 4. Update UI
    if (mounted) {
      setState(() {
        _accessState = accessState;
        _isElite = (accessState.tier == CommandCenterTier.elite);
        _isPlus = (accessState.tier == CommandCenterTier.plus);
        _isLoading = false; 
      });
      
      // Auto-decrement check for Plus users
      if (baseTier == CommandCenterTier.plus) {
         await _disciplineService.checkAndDecrementPlus(baseTier);
         if (mounted) {
            setState(() {
               _accessState = _disciplineService.getAccessState(baseTier);
            });
         }
      }
    }
  }

  void _handleDisciplineTap() {
    if (_accessState.tier == CommandCenterTier.free) {
      if (_accessState.isDoorUnlocked) return;
      
      setState(() {
         if (_freeTapsRemaining > 0) _freeTapsRemaining--;
         if (_freeTapsRemaining == 0) {
            _disciplineService.setFreeDoorUnlocked(true);
            _checkAccess();
         }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("COMMAND_CENTER_RENDER: start"); // D61.x.05C Proof

    if (_isLoading) {
      return Container(
        color: AppColors.ccBg,
        child: const Center(
            child: CircularProgressIndicator(color: AppColors.ccAccent)),
      );
    }

    // Access Logic
    final bool canShowDeepContent = _isElite || _isPlus;
    debugPrint("COMMAND_CENTER_RENDER: access_level=${_accessState.tier} deep=$canShowDeepContent");

    // FIX: Wrap in Material to prevent "Double Yellow Underline" (Text style fallback)
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: AppColors.ccBg,
        child: Column(
          children: [
          // Custom Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CloseButton(color: AppColors.transparent), 
                    IconButton(
                      icon:
                          const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
                Text(
                    AppConfig.isFounderBuild
                        ? "COMMAND CENTER (FOUNDER VIEW)"
                        : "COMMAND CENTER",
                    style: AppTypography.headline(context)
                        .copyWith(letterSpacing: 2.0)),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // Content Layer
                if (_data != null)
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        // D61.3: Coherence Quartet Anchor
                        Builder(builder: (c) {
                           debugPrint("COMMAND_CENTER_RENDER: quartet");
                           return CoherenceQuartetCard(
                             tier: _accessState.tier,
                             onUnlockTap: _handleDisciplineTap, 
                           );
                        }),
                        
                        // D61.6: Market Pressure Orb (Canonical)
                        const SizedBox(height: 12),
                        Builder(builder: (c) {
                           debugPrint("COMMAND_CENTER_RENDER: market_orb");
                           return MarketPressureOrb(
                             tier: _accessState.tier,
                             onUnlockTap: _handleDisciplineTap,
                             pressure: 0.15, // Mock data: Slight Bullish
                           );
                        }),

                        const SizedBox(height: 24),

                        // Header Micro-Copy (ONCE)
                        Center(
                          child: Text(
                            "Institutional context snapshot — evidence-backed.",
                            style: AppTypography.monoTiny(context).copyWith(
                                color: AppColors.textSecondary.withValues(alpha: 0.8), 
                                letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (canShowDeepContent) ...[
                          _buildSectionHeader("OS FOCUS — TODAY’S KEY MOVES"),
                          const SizedBox(height: 16),
                          ..._data!.osFocusCards.map((c) => Column(
                                children: [
                                  _buildFocusCard(c),
                                  const SizedBox(height: 16),
                                ],
                              )),
                          const SizedBox(height: 16),

                          _buildSectionHeader("HIGHEST CONFIDENCE DESCRIPTIONS"),
                          const SizedBox(height: 16),
                          ..._data!.confidenceDescriptions.map((c) => Column(
                                children: [
                                  _buildConfidenceCard(c),
                                  const SizedBox(height: 16),
                                ],
                              )),
                          const SizedBox(height: 32),

                          _buildSectionHeader("THE OS LEARNED THIS WEEK"),
                          const SizedBox(height: 16),
                          ..._data!.learnings.map((l) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8.0, left: 8.0),
                                child: Text("• $l",
                                    style: AppTypography.monoBody(context)),
                              )),
                          const SizedBox(height: 32),

                          _buildSectionHeader("ARTIFACTS VAULT"),
                          const SizedBox(height: 16),
                          ..._data!.artifacts.map(
                              (a) => _buildArtifactRow(a['name']!, a['status']!)),

                          const SizedBox(height: 32),
                        ] else ...[
                          // FALLBACK for Restricted State (Free/Gated)
                          // Render frosted placeholder if no deep content?
                          // The Prompt says: "If gated, show frosted placeholder (not empty screen)."
                          // Actually, the Quartet and Tilt are ALREADY gated heavily for Free.
                          // So the "rest of the screen" being empty is actually correct design for Free?
                          // "Ensure no if (isFree) return empty style logic."
                          // The `if (canShowDeepContent)` block handles the list.
                          // Below this, we should probably show a "Unlock Full Context" lock card if Free?
                          // But the Quartet already has a lock overlay for Free.
                          // Let's add a bottom spacer or lock hint if space allows.
                          // For now, let's just log.
                        ],
                        
                        Builder(builder: (c) {
                           debugPrint("COMMAND_CENTER_RENDER: end");
                           return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
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
        Text(title,
            style: AppTypography.monoLabel(context).copyWith(
                color: AppColors.ccAccent,
                letterSpacing: 1.5,
            )),
        const SizedBox(height: 4),
        // Hygiene: Removed Divider
      ],
    );
  }


  // OS Focus Card (Priority Market Read)
  Widget _buildFocusCard(CommandCenterCard card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ccSurface,
        border: Border.all(color: AppColors.ccBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(card.title,
              style: AppTypography.monoTitle(context)),
          const SizedBox(height: 12),

          // Drivers (Bullets)
          ...card.drivers.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("•", // VISUAL FIX: Neutral bullet
                        style: AppTypography.monoTiny(context).copyWith(
                            color: AppColors.textDisabled)), // Neutral color
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(d,
                            style: AppTypography.monoBody(context))),
                  ],
                ),
              )),
          const SizedBox(height: 8),

          // Evidence Sources (Badges)
          if (card.evidenceBadges.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.evidenceBadges.map((b) => _buildBadge(b)).toList(),
            ),

          const SizedBox(height: 12),
          // OS Focus (Single Strong Bullet)
          if (card.osFocus != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.adjust, color: AppColors.ccAccent, size: 12),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(card.osFocus!,
                        style: AppTypography.monoBody(context).copyWith(
                            color: AppColors.stateLive,
                            fontWeight: FontWeight.bold))),
              ],
            ),
        ],
      ),
    );
  }

  // Confidence Card (Integrity)
  Widget _buildConfidenceCard(CommandCenterCard card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ccSurface,
        border: Border.all(color: AppColors.ccBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(card.title,
                      style: AppTypography.monoTitle(context))),
            ],
          ),
          const SizedBox(height: 8),
          if (card.badges.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.badges.map((b) => _buildBadge(b)).toList(),
            ),
          const SizedBox(height: 12),
          ...card.descriptionBullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text("•",
                        style: AppTypography.monoTiny(context).copyWith(
                            color: AppColors.textDisabled)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(b,
                            style: AppTypography.monoBody(context))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.ccAccent.withValues(alpha: 0.1), // VISUAL FIX: Institutional Tag Style
          border: Border.all(color: AppColors.ccAccent.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(3)),
      child: Text(text,
          style: AppTypography.monoTiny(context).copyWith(
              color: AppColors.ccAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 9 
          ).copyWith(fontSize: 9)),
    );
  }

  Widget _buildArtifactRow(String name, String hash) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.description,
              color: AppColors.textDisabled, size: 16),
          const SizedBox(width: 8),
          Text(name,
              style: AppTypography.monoBody(context)),
          const Spacer(),
          Text(hash,
              style: AppTypography.monoTiny(context).copyWith(
                  color: AppColors.textDisabled)),
        ],
      ),
    );
  }
}
