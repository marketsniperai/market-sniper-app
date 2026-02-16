import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/command_center/command_center_tier.dart';

class MarketPressureOrb extends StatefulWidget {
  final CommandCenterTier tier;
  final VoidCallback? onUnlockTap;
  final double? pressure; // -1.0 (Bear) to 1.0 (Bull). Default 0.0.

  const MarketPressureOrb({
    super.key,
    required this.tier,
    this.onUnlockTap,
    this.pressure,
  });

  @override
  State<MarketPressureOrb> createState() => _MarketPressureOrbState();
}

class _MarketPressureOrbState extends State<MarketPressureOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Breathing loop: 7-8s for Neutral, 5-6s for Dominant (Active)
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 4)) // Base, adjusted in Tick
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Data & State Resolution
    final double rawPressure = widget.pressure ?? 0.0; // Default to pure neutral if missing
    final double pressure = rawPressure.clamp(-1.0, 1.0);

    final bool isBull = pressure > 0.05;
    final bool isBear = pressure < -0.05;
    final bool isNeutral = !isBull && !isBear;

    final bool isFree = widget.tier == CommandCenterTier.free;
    
    // Determine Pulse Speed based on intensity
    // We adjust duration on the fly? simpler to just use a standard breathing rate.
    // The prompt asks for variable speed. 
    // We can simulate this by scale factor or just keep it simple/calm.
    // Let's stick to a calm standard breathing to avoid jitter.
    
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return _buildOrbComposition(
            context,
            pressure,
            isBull,
            isBear,
            isNeutral,
            isFree,
          );
        },
      ),
    );
  }

  Widget _buildOrbComposition(
    BuildContext context,
    double pressure,
    bool isBull,
    bool isBear,
    bool isNeutral,
    bool isFree,
  ) {
    // Animation Values
    final double t = _controller.value; // 0.0 -> 1.0
    // Breathing: Scale slightly up/down. Very subtle.
    // Prompt: "1.01-1.02 max"
    final double breatheScale = 1.0 + (0.015 * t); 
    
    // Glow Pulse:
    final double glowOpacity = 0.3 + (0.2 * t); // 0.3 -> 0.5 (Subtle)

    // Color Logic for Glow
    Color glowColor = AppColors.ccAccent; // Cyan
    if (isBull) glowColor = AppColors.marketBull;
    if (isBear) glowColor = AppColors.marketBear;

    // Orb Size constraints
    // D61.x.07 Polish: 160px orb, Right aligned to create "Trinity" balance with Vol Meter
    const double orbSize = 160.0; 

    return Container(
      height: 180, 
      alignment: Alignment.centerRight, // Right Aligned
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Ambient Glow (Behind)
          Positioned(
             right: 4, // Center relative to right edge
             top: 10,
             child: Transform.scale(
              scale: breatheScale * 1.05,
              child: Container(
                width: orbSize,
                height: orbSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: isFree ? 0.0 : glowOpacity * 0.5),
                      blurRadius: 50,
                      spreadRadius: -10,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. The Physical Orb
          Positioned(
             right: 4,
             top: 10,
             child: GestureDetector(
                onTap: (widget.tier == CommandCenterTier.elite) 
                    ? () => _showExplainerModal(context) 
                    : widget.onUnlockTap,
                child: Transform.scale(
                  scale: breatheScale,
                  child: Container(
                    width: orbSize,
                    height: orbSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      // Glassy Shell
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF1A1F24), // Dark Core
                          Color(0xFF0D1114), // Darker Edge
                        ],
                        stops: [0.7, 1.0],
                      ),
                      boxShadow: [
                        // Rim Light
                        BoxShadow(
                            color: Colors.white10,
                            offset: Offset(-2, -2),
                            blurRadius: 4,
                            spreadRadius: 0),
                        // Shadow
                        BoxShadow(
                            color: Colors.black45,
                            offset: Offset(4, 4),
                            blurRadius: 10,
                            spreadRadius: 0),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 3. INTERNAL FLUID LAYERS
                          
                          // Base: Cyan Neutral Core (Always present, pulsating)
                          Center(
                            child: Container(
                              width: orbSize * 0.4,
                              height: orbSize * 0.4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.ccAccent.withValues(alpha: 0.2),
                                    AppColors.ccAccent.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Bullish Liquid (Rising)
                          if (isBull || isNeutral) // Even neutral has potential
                             _buildLiquidLayer(
                               context, 
                               isBull ? AppColors.marketBull : AppColors.ccAccent.withValues(alpha: 0.1),
                               Alignment.topCenter,
                               isBull ? pressure : 0.0, // Height based on pressure
                               orbSize
                             ),

                          // Bearish Liquid (Sinking)
                          if (isBear || isNeutral)
                             _buildLiquidLayer(
                               context, 
                               isBear ? AppColors.marketBear : AppColors.ccAccent.withValues(alpha: 0.1),
                               Alignment.bottomCenter,
                               isBear ? pressure.abs() : 0.0,
                               orbSize
                             ),

                          // 4. LABELS (Static, Inside)
                          if (!isFree) ...[
                            Positioned(
                              top: 30,
                              child: Text("BUYERS", 
                                style: AppTypography.monoTiny(context).copyWith(
                                  color: AppColors.marketBull.withValues(alpha: 0.9),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2
                                )),
                            ),
                            Center(
                              child: Text("NEUTRAL", 
                                style: AppTypography.monoTiny(context).copyWith(
                                  color: AppColors.ccAccent.withValues(alpha: 0.5),
                                  fontSize: 8,
                                  letterSpacing: 1.5
                                )),
                            ),
                            Positioned(
                              bottom: 30,
                              child: Text("SELLERS", 
                                style: AppTypography.monoTiny(context).copyWith(
                                  color: AppColors.marketBear.withValues(alpha: 0.9),
                                  fontSize: 9, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2
                                )),
                            ),
                          ],

                          // 5. Highlight / Lens Gloss (Gradient, no Blur to avoid artifacts)
                          Positioned(
                            top: 15,
                            left: 35,
                            child: Container(
                              width: 50,
                              height: 25,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.15),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                ),
                                borderRadius: const BorderRadius.all(Radius.elliptical(50, 25)),
                              ),
                            ),
                          ),

                          // 6. Gating (Blur)
                          if (isFree)
                             Positioned.fill(
                               child: BackdropFilter(
                                 filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                 child: Container(color: Colors.transparent),
                               ),
                             ),

                          if (isFree)
                            const Center(
                              child: Icon(Icons.lock_outline, color: AppColors.textDisabled, size: 24),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
             ),
          ),
          
          // 7. Info Icon (Outside, Floating Right)
          if (widget.tier == CommandCenterTier.elite)
            Positioned(
              right: 18, 
              top: 0,
              child: GestureDetector(
                onTap: () => _showExplainerModal(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ccSurface.withValues(alpha: 0.8),
                    border: Border.all(color: AppColors.ccBorder.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.info_outline, size: 14, color: AppColors.textDisabled),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiquidLayer(BuildContext context, Color color, Alignment align, double intensity, double size) {
    // Intensity 0.0 -> 1.0
    // Height of liquid = size * intensity (clamped to reasonable limits)
    // We used a simple LinearGradient before.
    // "Fill height = pressure magnitude."
    
    // Min visible liquid to show color tint?
    final double height = (size * 0.5) * (0.2 + (intensity * 0.8)); // At least 20% of hemi, up to 100%
    
    return Positioned(
      top: align == Alignment.topCenter ? 0 : null,
      bottom: align == Alignment.bottomCenter ? 0 : null,
      left: 0,
      right: 0,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: align,
            end: align == Alignment.topCenter ? Alignment.bottomCenter : Alignment.topCenter,
            colors: [
              color.withValues(alpha: 0.8),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  void _showExplainerModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.ccSurface,
        title: Text("Market Pressure", style: AppTypography.monoHero(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How to read the Orb", style: AppTypography.monoLabel(context).copyWith(color: AppColors.ccAccent)),
            const SizedBox(height: 8),
            Text(
              "This living object combines volume, price behavior, options structure, and regime stability into a single physical state.",
              style: AppTypography.body(context).copyWith(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
            ),
             const SizedBox(height: 16),
             _buildBullet(context, "Green Rise", "Buyers are lifting offers (Aggression)."),
             _buildBullet(context, "Red Sink", "Sellers are hitting bids (Liquidation)."),
             _buildBullet(context, "Cyan Core", "Equilibrium. No clear narrative dominance."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
             child: Text("CLOSE", style: AppTypography.monoLabel(context).copyWith(color: AppColors.ccAccent)),
          )
        ],
      ),
    );
  }

  Widget _buildBullet(BuildContext context, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: AppTypography.body(context).copyWith(color: AppColors.textDisabled)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.body(context).copyWith(fontSize: 12, color: AppColors.textSecondary),
                children: [
                   TextSpan(text: "$title: ", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                   TextSpan(text: desc),
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }
}
