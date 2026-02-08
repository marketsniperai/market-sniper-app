import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'coherence_quartet_tooltip.dart';
import '../../models/command_center/command_center_tier.dart';

class CoherenceQuartetCard extends StatefulWidget {
  final CommandCenterTier tier;
  final VoidCallback? onUnlockTap;
  final List<Map<String, dynamic>>? quartetData;

  const CoherenceQuartetCard({
    super.key,
    required this.tier,
    this.onUnlockTap,
    this.quartetData,
  });

  @override
  State<CoherenceQuartetCard> createState() => _CoherenceQuartetCardState();
}

class _CoherenceQuartetCardState extends State<CoherenceQuartetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 4s loop: 2s up, 2s down
    _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Log animation enabled for verification
    debugPrint("QUARTET_ANIM enabled");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safety Fallback if data is missing
    final data = widget.quartetData ?? _getMockData();

    // Tier Logic ('isElite' etc matches original logic)
    final isFree = widget.tier == CommandCenterTier.free;
    final isPlus = widget.tier == CommandCenterTier.plus;
    final isElite = widget.tier == CommandCenterTier.elite;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // Dev Log for layout verification (uncomment if needed continuously)
        // debugPrint("QUARTET_LAYOUT_OK w=$w");

        // Responsive adjustments
        final bool isCompact = w < 360; 
        final double chipHeight = isCompact ? 22 : 25;
        final double chipSpacing = isCompact ? 2 : 3;
        final double chipFontSize = isCompact ? 10 : 11;

        return Container(
          // height: 220, // VISUAL FIX: Removed fixed height
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.ccSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.ccBorder.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ccBg.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            children: [
              // 1. Content Layer
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Left Pane: Header + Tickers
                    Expanded(
                      flex: 5, // Slightly more distinct split
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Today’s Highest Confidence Setups",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.monoLabel(context).copyWith(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                    fontSize: isCompact ? 9 : 10,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showExplainerModal(context),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(Icons.info_outline, 
                                    size: isCompact ? 14 : 16, 
                                    color: AppColors.textDisabled),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Horizontal Divider (Thin) - REMOVED for Hygiene
                          // Container(height: 1, color: AppColors.ccBorder.withValues(alpha: 0.3)),
                          
                          const SizedBox(height: 4),

                          // Subtitle (Hide on very compact to save space)
                          if (!isCompact)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "Evidence-backed · Multi-factor",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.monoTiny(context).copyWith(
                                  color: AppColors.textDisabled,
                                  fontSize: 9, 
                                ),
                              ),
                            ),

                          // Tickers
                          Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildChip(context, data[0],
                                    visible: isElite || isPlus, isPos: true, 
                                    height: chipHeight, fontSize: chipFontSize),
                                SizedBox(height: chipSpacing),
                                _buildChip(context, data[1],
                                    visible: isElite, isPos: true, 
                                    height: chipHeight, fontSize: chipFontSize),
                                SizedBox(height: chipSpacing),
                                _buildChip(context, data[2],
                                    visible: isElite || isPlus, isPos: false, 
                                    height: chipHeight, fontSize: chipFontSize),
                                SizedBox(height: chipSpacing),
                                _buildChip(context, data[3],
                                    visible: isElite, isPos: false, 
                                    height: chipHeight, fontSize: chipFontSize),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: AppColors.ccBorder.withValues(alpha: 0.3),
                    ),

                    // Right Pane: Visualization (Living State)
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, vizConstraints) {
                             debugPrint("QUARTET_LAYOUT_OK w=$w left=${w*0.55} right=${vizConstraints.maxWidth}");
                             return RepaintBoundary(
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return _buildVisualization(isElite, isPlus, data, vizConstraints.maxWidth);
                                },
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Formatting / Frosting Layer
              if (!isElite) 
                Positioned.fill(
                  child: _buildFrostOverlay(context, isFree, isPlus),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(BuildContext context, Map<String, dynamic> item,
      {required bool visible, required bool isPos, required double height, required double fontSize}) {
    if (!visible) {
      // Blurred Chip Placeholder
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            height: height,
            width: 80, // Slightly smaller placeholder
            color: AppColors.ccSurfaceHigh.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    // Color Logic: Use Green for Pos, Red for Neg
    final Color scoreColor = isPos ? AppColors.marketBull : AppColors.marketBear;
    
    return GestureDetector(
        onTap: () {
          // Show tooltip overlay
          showDialog(
              context: context,
              builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: CoherenceQuartetTooltip(
                      symbol: item['symbol'],
                      score: item['score'],
                      whyHighConfidence: List<String>.from(item['why_high_confidence'] ?? []),
                      evidenceMemory: List<String>.from(item['evidence_memory'] ?? []),
                      regimeMacroOptions: List<String>.from(item['regime_macro_options'] ?? []),
                      invalidationRisk: item['risk'],
                      capitalActivity: item['capital_activity'],
                      humanConsensus: item['human_consensus'],
                    ),
                  ));
        },
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.ccSurfaceHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12), // Tighter radius
            border: Border.all(
                color: scoreColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible( // Prevent symbol overflow
                child: Text(
                  item['symbol'],
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoBody(context).copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: height * 0.4, color: AppColors.ccBorder), // Scaled divider
              const SizedBox(width: 8),
              Text(
                item['score'].toString(),
                style: AppTypography.monoTiny(context).copyWith(
                    fontSize: fontSize,
                    color: scoreColor),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildVisualization(
      bool isElite, bool isPlus, List<Map<String, dynamic>> data, double maxWidth) {
    
    // Animation factors
    final t = _controller.value;
    // Breathing: 1.0 -> 1.03 -> 1.0
    final breathScale = 1.0 + (t * 0.03);
    // Glow Blur: 16 -> 24 -> 16
    final flowBlur = 16.0 + (t * 8.0);
    // Glow Alpha: 0.18 -> 0.32 -> 0.18
    final flowAlpha = 0.18 + (t * 0.14);

    // Dynamic Sizing
    // We have a square constraint usually, roughly min(width, height)
    // Available height in Stack is ~ (220 - 32 padding) = 188.
    // VISUAL FIX: Reduced max size to 150 to prevent dominance
    final double size = math.min(maxWidth, 150.0);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Base Crosshair (Subtle)
          Center(child: Container(width: size, height: 1, color: AppColors.ccBorder.withValues(alpha: 0.1))),
          Center(child: Container(width: 1, height: size, color: AppColors.ccBorder.withValues(alpha: 0.1))),
          
          // Quadrants
          // Top Left (Pos 1) - Green
          if (isElite || isPlus)
            _buildLivingQuadrant(
                Alignment.topLeft,
                data[0]['score'],
                AppColors.marketBull, // Positive = Green
                breathScale, flowBlur, flowAlpha, size),
                
          // Top Right (Pos 2) - Green
          if (isElite)
            _buildLivingQuadrant(
                Alignment.topRight,
                data[1]['score'],
                AppColors.marketBull, // Positive = Green
                breathScale, flowBlur, flowAlpha, size),
                
          // Bottom Left (Neg 1) - Red
          if (isElite || isPlus)
            _buildLivingQuadrant(
                Alignment.bottomLeft,
                data[2]['score'],
                AppColors.marketBear, // Negative = Red
                breathScale, flowBlur, flowAlpha, size),
                
          // Bottom Right (Neg 2) - Red
          if (isElite)
            _buildLivingQuadrant(
                Alignment.bottomRight,
                data[3]['score'],
                AppColors.marketBear, // Negative = Red
                breathScale, flowBlur, flowAlpha, size),
        ],
      ),
    );
  }

  Widget _buildLivingQuadrant(Alignment alignment, dynamic scoreVal, Color baseColor,
      double scale, double blur, double alpha, double parentSize) {
    
    double score = 0.0;
    if (scoreVal is num) score = scoreVal.toDouble();
    
    final absScore = score.abs();
    
    // Radius Logic
    // Sqrt normalization: 0.85 -> 1.10 scale factor relative to quadrant size
    // Quadrant size is parentSize / 2.
    // Max radius circle should fit in quadrant (radius ~ parentSize/4 ?)
    // Let's say max radius is parentSize * 0.22 (leaving some padding)
    
    final double norm = math.min(absScore, 10.0) / 10.0; // 0..1
    final double radiusScale = 0.85 + (0.25 * math.sqrt(norm)); // 0.85 .. 1.10
    
    // VISUAL FIX: Reduced radius factor from 0.22 to 0.16 (~30% reduction)
    final double baseRadius = (parentSize * 0.16) * radiusScale;
    
    return Align(
      alignment: alignment,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: baseRadius * 2,
          height: baseRadius * 2,
          margin: EdgeInsets.all(parentSize * 0.05), // Avoid center overlap
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor.withValues(alpha: alpha), // Living Alpha
            boxShadow: [
              BoxShadow(
                  color: baseColor.withValues(alpha: alpha),
                  blurRadius: blur,
                  spreadRadius: 2)
            ],
            border: Border.all(color: baseColor.withValues(alpha: 0.5), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildFrostOverlay(BuildContext context, bool isFree, bool isPlus) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: isFree ? 10.0 : 0.0, sigmaY: isFree ? 10.0 : 0.0),
        child: Container(
          color: Colors.transparent, // Or subtle color
          child: Center(
            child: isFree
                ? _buildLockCTA(context, "Unlock Command Center")
                : (isPlus
                    ? null
                    : const SizedBox()), // Plus has no overlay, just partial hidden chips
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
        title: Text("System Engines", style: AppTypography.monoHero(context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExplainerItem(context, "Evidence Memory", "Historical pattern matching based on comparable market states."),
            const SizedBox(height: 12),
            _buildExplainerItem(context, "Macro Alignment", "Global liquidity and economic regime tailwinds."),
            const SizedBox(height: 12),
            _buildExplainerItem(context, "Options Structure", "Dealer positioning and volatility surface analysis."),
            const SizedBox(height: 12),
            _buildExplainerItem(context, "Cross-Asset", "Confirmations from Bond, FX, and Commodity markets."),
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

  Widget _buildExplainerItem(BuildContext context, String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(title, style: AppTypography.monoBody(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.ccAccent)),
         const SizedBox(height: 4),
         Text(desc, style: AppTypography.body(context).copyWith(color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
    ]);
  }

  Widget _buildLockCTA(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.ccBg.withValues(alpha: 0.9), // Slightly more opaque for legibility
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.ccAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 16, color: AppColors.ccAccent),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.body(context).copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ccAccent,
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockData() {
    return [
      {
        "symbol": "NVDA",
        "score": 9.2,
        "type": "POS",
        "why_high_confidence": ["Coherence Score > 9.0 (Exceptional)", "Multi-Regime Alignment"],
        "evidence_memory": ["Macro: Tailwind (AI CapEx)", "Volume: 150% Avg"],
        "regime_macro_options": ["Options: Call Skew > 2σ", "Regime: Expansion"],
        "risk": "Earnings in 3 days",
        "capital_activity": { "status": "N/A" },
        "human_consensus": { "status": "N/A" }
      },
      {
        "symbol": "MSFT",
        "score": 7.8,
        "type": "POS",
        "why_high_confidence": ["Stable Trend Alignment"],
        "evidence_memory": ["Technicals: Above 50DMA"],
        "regime_macro_options": ["Regime: Expansion", "Gamma: Positive"],
        "risk": null,
        "capital_activity": { "status": "N/A" },
        "human_consensus": { "status": "N/A" }
      },
      {
        "symbol": "TSLA",
        "score": -8.5,
        "type": "NEG",
        "why_high_confidence": ["Severe Put Wall Break"],
        "evidence_memory": ["Options: Put Wall Broken", "Macro: Headwind (Rates)"],
        "regime_macro_options": ["Regime: Volatility", "Gamma: Negative"],
        "risk": "Musk Tweet Volatility",
        "capital_activity": { "status": "N/A" },
        "human_consensus": { "status": "N/A" }
      },
      {
        "symbol": "AMD",
        "score": -6.1,
        "type": "NEG",
        "why_high_confidence": ["Sector Drag"],
        "evidence_memory": ["Sector: Semi Weakness"],
        "regime_macro_options": ["Technicals: Failed Breakout"],
        "risk": null,
        "capital_activity": { "status": "N/A" },
        "human_consensus": { "status": "N/A" }
      },
    ];
  }
}
