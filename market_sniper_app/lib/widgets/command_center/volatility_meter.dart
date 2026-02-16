import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../models/command_center/command_center_tier.dart';

class VolatilityMeter extends StatelessWidget {
  final CommandCenterTier tier;
  final VoidCallback? onUnlockTap;
  final double volatility; // 0.0 to 1.0 (Normalized VIX/IV)

  const VolatilityMeter({
    super.key,
    required this.tier,
    this.onUnlockTap,
    this.volatility = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Data Logic
    // Volatility > 0.7 = High (Red/Danger)
    // Volatility < 0.3 = Low (Green/Safe)
    // Mid = Orange/Warning
    Color needleColor = AppColors.marketBull;
    if (volatility > 0.4) needleColor = AppColors.ccAccent; // Normal
    if (volatility > 0.7) needleColor = AppColors.marketBear; // High Vola

    final bool isFree = tier == CommandCenterTier.free;

    return Container(
      height: 240, 
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. The Gauge Background (Half Circle or Radial)
          // We use a custom paint for precise "Meter" look.
          CustomPaint(
            size: const Size(200, 200),
            painter: _VolatilityPainter(volatility: volatility),
          ),

          // 2. The Needle (Animated Rotation)
          // Maps 0.0 -> -90 deg, 1.0 -> +90 deg
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: volatility),
            duration: const Duration(seconds: 2),
            curve: Curves.elasticOut,
            builder: (ctx, val, child) {
              // 0.0 = -pi/2 (Left), 0.5 = 0 (Up), 1.0 = pi/2 (Right)
              final angle = (val * math.pi) - (math.pi / 2);
              return Transform.rotate(
                angle: angle,
                alignment: Alignment.bottomCenter,
                child: child,
              );
            },
            child: Container(
              width: 4,
              height: 80,
              decoration: BoxDecoration(
                color: needleColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                   BoxShadow(color: needleColor.withValues(alpha: 0.5), blurRadius: 10)
                ]
              ),
              margin: const EdgeInsets.only(bottom: 80), // Offset from pivot
            ),
          ),

          // 3. Pivot Cap
          Container(
             width: 16,
             height: 16,
             decoration: BoxDecoration(
               color: AppColors.ccSurface,
               shape: BoxShape.circle,
               border: Border.all(color: AppColors.ccBorder),
               boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 4)]
             ),
          ),

          // 4. Labels
          Positioned(
             bottom: 40,
             child: Column(
               children: [
                 Text("VOLATILITY", 
                    style: AppTypography.monoTiny(context).copyWith(letterSpacing: 2, color: AppColors.textDisabled)),
                 const SizedBox(height: 4),
                 Text(volatility.toStringAsFixed(2),
                    style: AppTypography.monoHero(context).copyWith(fontSize: 24, color: needleColor)),
               ],
             )
          ),

          // 5. Gating Layer (Free)
          if (isFree)
            Positioned.fill(
               child: GestureDetector(
                 onTap: onUnlockTap,
                 child: Container(
                   color: AppColors.bgDeepVoid.withValues(alpha: 0.8),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        const Icon(Icons.lock, color: AppColors.textDisabled),
                        const SizedBox(height: 8),
                         Text("LOCKED", style: AppTypography.monoTiny(context)),
                     ],
                   ),
                 ),
               ),
            ),
            
          // 6. Info Button (Right Top)
          if (!isFree)
             Positioned(
               right: 0,
               top: 0,
               child: IconButton(
                 icon: const Icon(Icons.info_outline, size: 16, color: AppColors.textDisabled),
                 onPressed: () => _showExplainer(context),
               ),
             ),
        ],
      ),
    );
  }

  void _showExplainer(BuildContext context) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
           backgroundColor: AppColors.ccSurface,
           title: Text("Implied Volatility", style: AppTypography.monoHero(context)),
           content: Text("Measures the market's expectation of future range expansion. High values indicate fear or opportunity; low values indicate complacency.", style: AppTypography.body(context)),
        )
      );
  }
}

class _VolatilityPainter extends CustomPainter {
  final double volatility;
  _VolatilityPainter({required this.volatility});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw Arc
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Gradient Arc?
    // Low (Green) -> Mid (Orange) -> High (Red)
    // Left (-pi) to Right (0) -- Wait, we defined -pi/2 to pi/2 in rot logic.
    // Let's match: -pi/2 (Up-Left? No 12 oclock is -pi/2 usually in flutter canvas start)
    // Flutter 0 is 3 oclock.
    // We want -180 (9 oclock) to 0 (3 oclock)? Or 135 to 45?
    // Let's use 180 degree arc: From 9 oclock (pi) to 3 oclock (0)? No, upside down.
    // Typically gauge: 9 o'clock to 3 o'clock. 
    // StartAngle = pi. SweepAngle = pi.
    
    // Segments
    // 1. Safe (Green)
    paint.color = AppColors.marketBull.withValues(alpha: 0.2);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi * 0.3, false, paint);

    // 2. Normal (Cyan/Orange)
    paint.color = AppColors.ccAccent.withValues(alpha: 0.2);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi + (math.pi*0.3), math.pi * 0.4, false, paint);
    
    // 3. Danger (Red)
    paint.color = AppColors.marketBear.withValues(alpha: 0.2);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi + (math.pi*0.7), math.pi * 0.3, false, paint);

    // Ticks
    // ...
  }

  @override
  bool shouldRepaint(_VolatilityPainter oldDelegate) => false;
}
