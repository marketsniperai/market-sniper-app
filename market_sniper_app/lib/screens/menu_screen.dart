// ignore_for_file: deprecated_member_use, unnecessary_null_in_if_null_operators
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../config/app_config.dart';
import '../screens/premium_screen.dart';
import '../screens/language_screen.dart';
import '../screens/account_screen.dart';
import '../screens/partner_terms_screen.dart';
import '../screens/ritual_preview_screen.dart'; // Polish
import '../services/human_mode_service.dart'; // Polish
import '../services/notification_service.dart';
import '../guards/access_policy.dart'; // Founder Law
import 'package:market_sniper_app/widgets/atoms/neon_outline_card.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'package:provider/provider.dart';
import '../state/locale_provider.dart';
import '../repositories/elite_repository.dart'; // D49
import '../widgets/elite/elite_reflection_modal.dart'; // D49

class MenuScreen extends StatefulWidget {
  final VoidCallback? onClose; // Shell Compliance
  final Function(Widget)? onNavigate; // Shell Compliance: In-Shell Navigation
  const MenuScreen({super.key, this.onClose, this.onNavigate});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // Toggles
  bool _notificationsEnabled = false;
  bool _eliteAutolearn = false; // D49
  // final bool _humanModeEnabled = false; // REMOVED (Unused) // Stub state

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notifs = await NotificationService().isEnabled();
    if (mounted) setState(() => _notificationsEnabled = notifs);
  }

  String _getLangName(BuildContext context) {
    // Watch provided locale for dynamic subtitle
    final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
    switch (lang) {
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'hi':
        return 'Hindi (हिंदी)';
      case 'zh':
        return '中文 (Chinese)';
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Embedded Layout (No Scaffold)
    // HOTFIX.MENU.SHELL.03: Self-Heal Material Ancestor
    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: AppColors.bgPrimary, // Ensure background opacity
        child: Column(
          children: [
            // Custom Header (Replaces AppBar)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (Calls onClose)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.pop(
                            context); // Fallback for standalone testing
                      }
                    },
                  ),
                  // Title
                  Text(
                    "MENU",
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                  // Balance (Invisible 48px box)
                  const SizedBox(width: 48, height: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Toggles Section
                    AppSpacing.gapCard,
                    _buildSectionHeader("PREFERENCES"),
                    AppSpacing.gapAction,
                    _buildToggleItem(
                      "Notifications",
                      _notificationsEnabled,
                      (val) {
                        setState(() => _notificationsEnabled = val);
                        NotificationService().setEnabled(val).then((_) {
                          if (!context.mounted) return;
                          if (val) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Ritual Notifications Enabled (Daily 9:20 AM / 4:05 PM ET)")));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Ritual Notifications Disabled")));
                          }
                        });
                      },
                    ),
                    // D53: Human Mode Toggle (Founder Only - HF-1 Law forces Public ON)
                    if (AppConfig.isFounderBuild) ...[
                      AppSpacing.gapAction,
                      _buildToggleItem(
                        "Human Mode",
                        HumanModeService().enabled,
                        (val) {
                          HumanModeService().setEnabled(val);
                          setState(() {}); // Local update for the switch UI
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              val
                                  ? "Human Mode Enabled (Explanatory Tone)"
                                  : "Human Mode Disabled (Institutional Tone)",
                            ),
                            duration: const Duration(seconds: 1),
                          ));
                        },
                      ),
                    ],
                    AppSpacing.gapAction,
                    
                    // D49: Elite Autolearn Toggle
                    _buildToggleItem(
                       "Elite Autolearn (Cloud)",
                       _eliteAutolearn,
                       (val) {
                          setState(() => _eliteAutolearn = val);
                          // Fire and Forget Save
                          ApiClient().post('/elite/settings', {"elite_autolearn": val});
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                             content: Text(val ? "Cloud Autolearn Enabled (PII Scrubbed)" : "Autolearn Disabled (Local Only)")));
                       }
                    ),
                    
                    if (AppConfig.isFounderBuild) ...[
                        AppSpacing.gapAction,
                        Center(child: TextButton(
                           child: const Text("DEBUG: Daily Reflection", style: TextStyle(color: AppColors.textDisabled, fontSize: 10)),
                           onPressed: () {
                              // Open Reflection Modal
                              _showReflectionModal(context); 
                           }
                        )),
                    ],

                    AppSpacing.gapSection,

                    // 2. Main Actions
                    _buildSectionHeader("ACCOUNT & SYSTEM"),
                    AppSpacing.gapAction,

                    _buildMenuItem("Account", () {
                      if (widget.onNavigate != null) {
                        widget.onNavigate!(AccountScreen(
                          onBack: () => widget.onNavigate!(MenuScreen(
                              onClose: widget.onClose,
                              onNavigate: widget.onNavigate)),
                          onNavigate: widget.onNavigate,
                        ));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AccountScreen()));
                      }
                    }, subtitle: "Partner Protocol (Beta)"),

                    AppSpacing.gapAction,
                    _buildMenuItem("Premium Protocol", () {
                      if (widget.onNavigate != null) {
                        widget.onNavigate!(PremiumScreen(
                            onBack: () => widget.onNavigate!(MenuScreen(
                                onClose: widget.onClose,
                                onNavigate: widget.onNavigate))));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PremiumScreen()));
                      }
                    }),

                    AppSpacing.gapAction,
                    _buildMenuItem("Language", () {
                      if (widget.onNavigate != null) {
                        widget.onNavigate!(LanguageScreen(
                            onBack: () => widget.onNavigate!(MenuScreen(
                                onClose: widget.onClose,
                                onNavigate: widget.onNavigate))));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LanguageScreen()));
                      }
                    }, subtitle: _getLangName(context)),

                    if (AppConfig.isFounderBuild) ...[
                      AppSpacing.gapAction,
                      // Share Attribution Removed (Replaced by Language)

                      // Debug - De-emphasized
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: TextButton(
                              onPressed: () {
                                // Validating Founder Law: Should BYPASS preview if Founder.
                                if (AccessPolicy.founderAlwaysOn) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Founder Law: Bypassing Preview -> Briefing")));
                                  // Simulate routing to Dashboard (Briefing target)
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const LanguageScreen()),
                                      (route) => false);
                                } else {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const RitualPreviewScreen(
                                              title: "Morning Briefing",
                                              description:
                                                  "Institutional context for the opening bell. Align your execution with daily structural levels.")));
                                }
                              },
                              child: Text("DEBUG: Test Ritual Routing",
                                  style: GoogleFonts.inter(
                                      color: AppColors.textDisabled,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500))),
                        ),
                      ),
                    ],

                    AppSpacing.gapSection,

                    // 3. Info / Legal
                    _buildSectionHeader("ABOUT"),
                    AppSpacing.gapAction,

                    _buildMenuItem("About Us",
                        () => _showModal(context, "About Us", _aboutContent)),
                    AppSpacing.gapAction,
                    _buildMenuItem("Legal",
                        () => _showModal(context, "Legal", _legalContent)),

                    const SizedBox(height: 48),
                    Center(
                      child: Text(
                        "v1.0.5 (Polished)",
                        style: GoogleFonts.inter(
                            color: AppColors.textDisabled,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          // Inter
          color: AppColors.textSecondary.withOpacity(0.7), // More subtle
          fontSize: 11, // Smaller
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildToggleItem(
      String label, bool value, ValueChanged<bool> onChanged) {
    return NeonOutlineCard(
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.neonCyan,
            activeTrackColor: AppColors.neonCyan.withOpacity(0.3),
            inactiveThumbColor: AppColors.textDisabled,
            inactiveTrackColor: AppColors.bgDeepVoid,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String label, VoidCallback onTap, {String? subtitle}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: NeonOutlineCard(
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(context).copyWith(
                        color: AppColors.neonCyan.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: AppColors.textDisabled), // Smaller icon
          ],
        ),
      ),
    );
  }

  // --- Modal Logic ---

  void _showModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: true, // Tap outside closes
      barrierColor: AppColors.shadow.withOpacity(0.85), // Dark scrim
      builder: (context) => Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSubtle),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      if (title == "Legal") ...[
                        const SizedBox(height: 24),
                        Center(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close modal first
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PartnerTermsScreen()));
                            },
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.borderSubtle)),
                            child: Text("Open Partner Terms",
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary)),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReflectionModal(BuildContext context) {
     showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => EliteReflectionModal(onComplete: () {
           // Maybe close menu too? 
           // Navigator.pop(context); 
        })
     );
  }

  static const String _aboutContent = """
MARKET SNIPER AI
Version 1.0.5 (Polish Phase)

We are a specialized intelligence platform designed to empower institutional and retail traders with high-precision market signals.

Engineered for speed, clarity, and truth, Market Sniper eliminates noise and focuses on what matters: actionable data states and verifiable system health.

(c) 2026 Market Sniper AI. All Rights Reserved.
""";

  static const String _legalContent = """
LEGAL DISCLAIMER

1. No Financial Advice
Market Sniper AI provides data aggregation and system health simulations. Nothing herein constitutes financial, investment, or legal advice.

2. Risk of Loss
Trading involves substantial risk. You are solely responsible for your decisions.

3. "Founder Mode"
Features labeled "Founder" or "Elite" are experimental surfaces for internal validation and do not represent guaranteed capabilities of the public release.

4. Data Integrity
While we strive for precision, data feeds (especially in simulation mode) may be synthetic or delayed.

By using this application, you agree to these terms.
""";
}
