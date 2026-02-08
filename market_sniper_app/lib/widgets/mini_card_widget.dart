import 'package:flutter/material.dart';
import 'dart:ui' as import_ui;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class MiniCardWidget extends StatelessWidget {
  final String ticker;
  final String timeframe;
  final String reliability;
  final String topBullet;
  
  const MiniCardWidget({
    super.key,
    required this.ticker,
    required this.timeframe,
    required this.reliability,
    required this.topBullet,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed size for consistency and small file size
    return Container(
      width: 300,
      height: 400,
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        border: Border.fromBorderSide(BorderSide(color: AppColors.neonCyan, width: 2)),
      ),
      child: Stack(
        children: [
          // Background Gradient or Effect
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface1,
                    AppColors.surface2,
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticker,
                      style: AppTypography.headline(context).copyWith(
                        fontSize: 32,
                        color: AppColors.textPrimary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.textDisabled),
                      ),
                      child: Text(
                        timeframe,
                        style: AppTypography.caption(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  width: 40,
                  color: AppColors.neonCyan,
                ),
                
                const Spacer(),
                
                // Reliability Gauge (Visual)
                Text("RELIABILITY", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildGaugeSegment(context, true, AppColors.stateLocked),
                    const SizedBox(width: 4),
                    _buildGaugeSegment(context, reliability != 'LOW', AppColors.stateStale),
                    const SizedBox(width: 4),
                    _buildGaugeSegment(context, reliability == 'HIGH', AppColors.stateLive),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reliability, 
                  style: AppTypography.label(context).copyWith(
                    color: reliability == 'HIGH' ? AppColors.stateLive : (reliability == 'LOW' ? AppColors.stateLocked : AppColors.stateStale),
                    fontWeight: FontWeight.bold
                  )
                ),
                
                const Spacer(),
                
                // Intel Teaser
                Text(
                  "INSTITUTIONAL INTEL",
                  style: AppTypography.caption(context).copyWith(
                    color: AppColors.neonCyan,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  topBullet,
                  style: AppTypography.body(context).copyWith(
                    fontSize: 16,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Blurred Lines to simulate more content
                _buildBlurredLine(),
                const SizedBox(height: 4),
                _buildBlurredLine(width: 150),
                
                const Spacer(),
                
                // Footer
                Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.neonCyan, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "MarketSniper AI",
                      style: AppTypography.label(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                 Text(
                   "Institutional Machinery",
                   style: AppTypography.caption(context).copyWith(
                     fontStyle: FontStyle.italic,
                     fontSize: 10,
                     color: AppColors.textDisabled,
                   ),
                 ),
              ],
            ),
          ),
          
          // Corner Accent
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(40, 40),
              painter: _CornerPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeSegment(BuildContext context, bool active, Color color) {
    return Expanded(
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: active ? color : AppColors.surface2,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
  
  Widget _buildBlurredLine({double width = double.infinity}) {
     return Container(
       width: width,
       height: 12,
       decoration: BoxDecoration(
         color: AppColors.surface2.withValues(alpha: 0.5),
         borderRadius: BorderRadius.circular(4),
       ),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(4),
         child: BackdropFilter(
           filter: import_ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
           child: Container(color: AppColors.transparent),
         ),
       ),
     );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonCyan
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
