import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../config/app_config.dart';
import '../logic/premium_status_resolver.dart';
import '../logic/plus_unlock_engine.dart'; // D45.14
import '../logic/command_center/command_center_builder.dart'; // D45.15
import '../logic/share/viral_teaser_store.dart'; // D45.16
// D45.16
import '../models/premium/premium_matrix_model.dart'; // Verified import

class CommandCenterScreen extends StatefulWidget {
  final VoidCallback? onBack; // Shell Compliance
  const CommandCenterScreen({super.key, this.onBack});

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
  // bool _showTeaserBanner = false; // REMOVED (Unused)

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadData();
    // _checkTeaser(); // REMOVED (dead code)
  }

  /* REMOVED (Dead code, unused variable _showTeaserBanner)
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
  */

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
      return Container(
        color: AppColors.bgDeepVoid,
        child: const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
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

    return Container(
      color: AppColors.bgDeepVoid,
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
                    const CloseButton(color: Colors.transparent), // Balancer
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
                // Content Layer (Always built, maybe blurred/frosted)
                if (_data != null)
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Micro-Copy (ONCE)
                        Center(
                          child: Text(
                            "Institutional context snapshot — evidence-backed.",
                            style: AppTypography.body(context).copyWith(
                                color: AppColors.textDisabled,
                                fontSize: 10,
                                letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),

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
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontFamily: 'RobotoMono')),
                            )),
                        const SizedBox(height: 32),

                        _buildSectionHeader("ARTIFACTS VAULT"),
                        const SizedBox(height: 16),
                        ..._data!.artifacts.map(
                            (a) => _buildArtifactRow(a['name']!, a['status']!)),

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
                                const Icon(Icons.lock,
                                    color: AppColors.stateLocked, size: 48),
                                const SizedBox(height: 16),
                                Text("ELITE CLEARANCE REQUIRED",
                                    style: AppTypography.headline(context)
                                        .copyWith(
                                            color: AppColors.stateLocked)),
                                const SizedBox(height: 8),
                                Text("Command Center access is restricted.",
                                    style: AppTypography.body(context)),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface1,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: AppColors.neonCyan),
                                  ),
                                  child: Text("PLUS PROGRESS: $_plusProgress",
                                      style: const TextStyle(
                                          color: AppColors.neonCyan,
                                          fontSize: 11,
                                          fontFamily: 'RobotoMono',
                                          fontWeight: FontWeight.bold)),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Frosted Layer for Free (Institutional Tease)
                if (locked)
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: AppColors.bgDeepVoid
                              .withValues(alpha: 0.8), // Frosted look
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.visibility_off,
                                    color: AppColors.textDisabled, size: 48),
                                const SizedBox(height: 16),
                                Text("RESTRICTED SURFACE",
                                    style: AppTypography.headline(context)
                                        .copyWith(
                                            color: AppColors.textDisabled,
                                            letterSpacing: 2.0)),
                                const SizedBox(height: 8),
                                Text("Institutional context available inside.",
                                    style: AppTypography.body(context).copyWith(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
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
            style: const TextStyle(
                color: AppColors.neonCyan,
                fontSize: 10,
                letterSpacing: 1.5,
                fontFamily: 'RobotoMono',
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
            height: 1, color: AppColors.neonCyan.withValues(alpha: 0.3)),
      ],
    );
  }

  // OS Focus Card (Priority Market Read)
  Widget _buildFocusCard(CommandCenterCard card) {
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
          // Title
          Text(card.title,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'RobotoMono')),
          const SizedBox(height: 12),

          // Drivers (Bullets)
          ...card.drivers.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(">",
                        style: TextStyle(
                            color: AppColors.neonCyan,
                            fontSize: 10,
                            fontFamily: 'RobotoMono')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(d,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'RobotoMono'))),
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
                const Icon(Icons.adjust, color: AppColors.neonCyan, size: 12),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(card.osFocus!,
                        style: const TextStyle(
                            color: AppColors.stateLive,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'RobotoMono'))),
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
        color: AppColors.surface1,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(card.title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RobotoMono'))),
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
                    const Text("•",
                        style: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 10,
                            fontFamily: 'RobotoMono')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(b,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'RobotoMono'))),
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
          color: AppColors.neonCyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3)),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.neonCyan,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
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
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'RobotoMono')),
          const Spacer(),
          Text(hash,
              style: const TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 10,
                  fontFamily: 'RobotoMono')),
        ],
      ),
    );
  }
}
