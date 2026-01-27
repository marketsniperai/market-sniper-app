import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
// Kept for signature, but stubbed usage
import '../theme/app_colors.dart';
import '../config/app_config.dart';
import 'partner_terms_screen.dart';
import '../widgets/atoms/neon_outline_card.dart';
import '../theme/app_typography.dart';

// --- Stubs for Missing Dependencies (Internal to file to avoid pollution) ---



// ---------------------------------------------------------------------------

class AccountScreen extends StatefulWidget {
  final VoidCallback? onBack; // Shell Compliance
  final Function(Widget)? onNavigate; // Shell Compliance
  const AccountScreen({super.key, this.onBack, this.onNavigate});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // MOCK DATA
  final String plan = "Elite";
  final DateTime billingDate = DateTime.now().add(const Duration(days: 14));
  // Removed unused mock data

  @override
  Widget build(BuildContext context) {

    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          // Custom Header (Replaces AppBar)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Back Button (Left Aligned)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: AppColors.textPrimary),
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                // Centered Title & Identity
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "My Account",
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                    if (plan == 'Elite') // Mock 'Founder' check
                      Text(
                        "Founder privileges active",
                        style: AppTypography.caption(context).copyWith(
                          color: AppColors.textSecondary.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // COMPACT PLAN CARD
                  _buildPremiumCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color:
                                          AppColors.neonCyan.withValues(alpha: 0.5),
                                      width: 1)),
                              child: const CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.surface2,
                                child: Icon(Icons.person,
                                    size: 24, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("User",
                                      style: GoogleFonts.inter(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  Text("user@example.com",
                                      style: GoogleFonts.inter(
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.7),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.gapSection,
                        Divider(color: AppColors.textPrimary.withValues(alpha: 0.1)),
                        AppSpacing.gapCard,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("CURRENT PLAN",
                                    style: GoogleFonts.jetBrainsMono(
                                        color: AppColors.textSecondary,
                                        fontSize: 10,
                                        letterSpacing: 1.2)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(plan.toUpperCase(),
                                        style: GoogleFonts.inter(
                                            color: AppColors.textPrimary,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0)),
                                    if (plan == 'Elite')
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: AppColors.stateLive
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: AppColors.stateLive
                                                    .withValues(alpha: 0.5))),
                                        child: const Text("FOUNDER",
                                            style: TextStyle(
                                                color: AppColors.stateLive,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold)),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (plan == 'Elite')
                                  const Text("\$149/mo",
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        AppSpacing.gapCard,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("NEXT BILLING",
                                    style: GoogleFonts.jetBrainsMono(
                                        color: AppColors.textSecondary,
                                        fontSize: 10)),
                                const SizedBox(height: 2),
                                Text(
                                    DateFormat('MMM dd, yyyy')
                                        .format(billingDate),
                                    style: const TextStyle(
                                        color: AppColors.textPrimary, fontSize: 13)),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _manageSub(context),
                              style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 0),
                                  backgroundColor:
                                      AppColors.neonCyan.withValues(alpha: 0.1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              child: const Text("Manage",
                                  style: TextStyle(
                                      color: AppColors.neonCyan,
                                      fontSize: 12)),
                            )
                          ],
                        )
                      ],
                    ),
                  ),

                  AppSpacing.gapSection,

                  // PARTNER PROTOCOL
                  _buildPartnerProtocolCard(context),

                  AppSpacing.gapSection,

                  // ACCOUNT ACTIONS (Log Out Button)
                  Center(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.textDisabled.withValues(alpha: 0.3)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                      child: Text("Log Out",
                          style: TextStyle(
                              color: AppColors.marketBear.withValues(alpha: 0.8),
                              fontSize: 14)),
                    ),
                  ),

                  SizedBox(height: AppSpacing.sectionGap * 2),
                  Text("MarketSniper AI v4.3.0",
                      style: TextStyle(
                          color: AppColors.textDisabled.withOpacity(0.3),
                          fontSize: 10)),
                ],
              ),
              ),
            ),

        ],
      ),
    );
  }

  void _manageSub(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface1,
              title: const Text("Manage Subscription",
                  style: TextStyle(color: AppColors.textPrimary)),
              content: const Text(
                  "Downgrade and Cancellation options will be available shortly.",
                  style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"))
              ],
            ));
  }



  Widget _buildPartnerProtocolCard(BuildContext context) {
    return _FlipCard(
      front: _buildPartnerProtocolFront(context),
      back: _buildPartnerProtocolBack(context),
    );
  }

  Widget _buildPartnerProtocolFront(BuildContext context) {
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Partner Protocol",
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.hub_outlined, color: AppColors.neonCyan.withValues(alpha: 0.8), size: 16),
                  const SizedBox(width: 12),
                  // Dedicated Flip Trigger
                  const Icon(Icons.info_outline, color: AppColors.textSecondary, size: 16),
                ],
              ),
            ],
          ),
          AppSpacing.gapAction,

          // Code Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: AppColors.bgDeepVoid, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("MS-FOUNDER-888",
                    style: TextStyle(
                        color: AppColors.neonCyan,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                      IconButton(
                        icon: Icon(Icons.copy,
                            size: 16, color: AppColors.textPrimary.withValues(alpha: 0.54)),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text("Stub: Code Copied"))),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.share,
                            size: 16, color: AppColors.textPrimary.withValues(alpha: 0.54)),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                content: Text("Stub: Share Intent"))),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                )
              ],
            ),
          ),

          AppSpacing.gapCard,
          // Tier Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.start, // Tight spacing
            children: [
              _buildTierBadge(context, "Collaborator", AppColors.neonCyan, true),
              const SizedBox(width: 8),
              _buildTierBadge(context, "Entrepreneur", AppColors.textDisabled, false),
              const SizedBox(width: 8),
              _buildTierBadge(context, "Partner", AppColors.textDisabled, false),
              const SizedBox(width: 8),
              _buildTierBadge(context, "Inst.", AppColors.textDisabled, false),
            ],
          ),

          AppSpacing.gapSection,
          
          // Custom Progress Bar
          Stack(
            children: [
              Container(
                height: 2,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.2, // 2/10
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 0,
                      )
                    ]
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("2 / 10 eligible operators",
                  style: AppTypography.caption(context).copyWith(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w600)),
            ],
          ),

          const SizedBox(height: 4),
          Text("10 eligible operators required to activate Partner Credits.",
              style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10)), // Reduced opacity/size

          AppSpacing.gapAction,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
            onPressed: () {
              if (widget.onNavigate != null) {
                widget.onNavigate!(PartnerTermsScreen(
                    onBack: () => widget.onNavigate!(widget)));
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PartnerTermsScreen()));
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              backgroundColor: AppColors.surface2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            child: const Text("Terms",
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11)),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerProtocolBack(BuildContext context) {
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Partner Protocol",
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              Icon(Icons.hub_outlined, color: AppColors.neonCyan.withValues(alpha: 0.8), size: 16),
            ],
          ),
          AppSpacing.gapCard,
          
          _buildBackBullet(context, "Invite trusted operators using your Invite Code."),
          const SizedBox(height: 8),
          _buildBackBullet(context, "Partner Credits activate after 10 eligible paid members."),
          const SizedBox(height: 8),
          _buildBackBullet(context, "Credits are governed by Program Terms."),

          AppSpacing.gapCard,
           // Mini Tier Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
               Icon(Icons.verified, size: 12, color: AppColors.neonCyan),
               const SizedBox(width: 4),
               Text("Collaborator", style: TextStyle(color: AppColors.neonCyan, fontSize: 10)),
               const SizedBox(width: 8),
               Container(width: 1, height: 10, color: AppColors.textDisabled.withValues(alpha: 0.3)),
               const SizedBox(width: 8),
               Text("+3 Levels", style: TextStyle(color: AppColors.textDisabled, fontSize: 10)),
            ],
          ),

          AppSpacing.gapSection,
          Text("MarketSniper AI reserves the right to modify or terminate the program at any time.",
              style: TextStyle(
                  color: AppColors.textDisabled.withValues(alpha: 0.5),
                  fontSize: 9, fontStyle: FontStyle.italic)),

           AppSpacing.gapCard,
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                if (widget.onNavigate != null) {
                  widget.onNavigate!(PartnerTermsScreen(
                      onBack: () => widget.onNavigate!(widget)));
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PartnerTermsScreen()));
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.surface2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
              ),
              child: const Text("View Full Program Terms",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackBullet(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Icon(Icons.circle, size: 4, color: AppColors.neonCyan.withValues(alpha: 0.5)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                  fontSize: 12, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildTierBadge(BuildContext context, String label, Color color, bool isActive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? color : color.withValues(alpha: 0.3)),
            color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          ),
          child: Icon(
            isActive ? Icons.verified : Icons.lock_outline,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: AppTypography.badge(context).copyWith(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal))
      ],
    );
  }

  Widget _buildPremiumCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [
                AppColors.neonCyan.withValues(alpha: 0.12),
                AppColors.bgDeepVoid
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: child,
    );
  }
}

class _FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  const _FlipCard({required this.front, required this.back});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _animation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // Detect tap in top-right corner area (approx 48x48)
        // Card width is screen width - 48 (padding 24*2)
        // Local position check is simpler if we wrap the icon, but user requested tap icon.
        // However, we can also just let the whole card map taps if they are NOT on buttons.
        // BUT constraints said: "Flip must be triggered via a dedicated small icon/button"
        // So we wrap the whole card in GestureDetector just to catch taps on the icon area? 
        // Or simpler: Pass a callback to the Front widget to trigger flip.
        // Refactoring to pass callback down is cleaner.
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159; // PI
          final isBack = angle > 1.5708; // PI/2
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: Stack(
                      children: [
                        widget.back,
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: _toggleFlip,
                            child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(color: AppColors.bgDeepVoid.withValues(alpha:0.5), shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary)),
                          ),
                        )
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      widget.front,
                      Positioned(
                        top: 16,
                        right: 40, // 16 + 16(hub) + 12(spacing) approx? No, row approach better.
                        // Actually, since I rendered the icon inside the Front widget Row, I should just make THAT icon tappable.
                        // But I need access to _toggleFlip from inside existing structure.
                        // A Stack overlay here is safest to guarantee hit test without refactoring deeply.
                        // Let's place a transparent hit target over the top-right area.
                        child: GestureDetector(
                            onTap: _toggleFlip,
                            child: Container(
                              width: 48, height: 48,
                              color: Colors.transparent, 

                            )
                        ),
                      ) 
                    ],
                  ),
          );
        },
      ),
    );
  }
}
