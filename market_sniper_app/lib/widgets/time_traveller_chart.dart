import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'blurred_truth_overlay.dart'; // D47.HF30

class ChartCandle {
  final double o;
  final double h;
  final double l;
  final double c;
  final bool isGhost;

  ChartCandle({
    required this.o,
    required this.h,
    required this.l,
    required this.c,
    this.isGhost = false,
  });

  factory ChartCandle.fromJson(Map<String, dynamic> json) {
    return ChartCandle(
      o: (json['o'] as num).toDouble(),
      h: (json['h'] as num).toDouble(),
      l: (json['l'] as num).toDouble(),
      c: (json['c'] as num).toDouble(),
      isGhost: json['isGhost'] ?? false,
    );
  }
}

class TimeTravellerChart extends StatefulWidget {
  final List<ChartCandle> pastCandles;
  final List<ChartCandle> futureCandles;
  final bool isLocked;
  final bool isCalibrating;
  final double height;
  final bool blurFuture; // D47.HF30

  const TimeTravellerChart({
    super.key,
    required this.pastCandles,
    required this.futureCandles,
    this.isLocked = false,
    this.isCalibrating = false,
    this.height = 200,
    this.blurFuture = false,
  });

  @override
  State<TimeTravellerChart> createState() => _TimeTravellerChartState();
}

class _TimeTravellerChartState extends State<TimeTravellerChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Sequential reveal loop
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If calibrating or no data, show Calibrating Trace
    if (widget.isCalibrating || (widget.pastCandles.isEmpty && widget.futureCandles.isEmpty)) {
      return Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Stack(
          children: [
             Positioned.fill(child: CustomPaint(painter: _GhostTracePainter())),
             Center(child: Text("CALIBRATING", style: AppTypography.caption(context).copyWith(color: AppColors.neonCyan))),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final nowX = constraints.maxWidth * 0.66;
        final futureWidth = constraints.maxWidth - nowX;

        return Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: ClipRect( // Clip for drawing bounds
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Canvas
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ChartPainter(
                          past: widget.pastCandles,
                          future: widget.futureCandles,
                          isLocked: widget.isLocked,
                          animationValue: _animation.value,
                        ),
                      ),
                    ),
                    
                    // Blurred Truth Hook (HF30)
                    if (widget.blurFuture && !widget.isLocked) 
                       Positioned(
                         left: nowX,
                         top: 0,
                         width: futureWidth,
                         height: constraints.maxHeight,
                         child: BlurredTruthOverlay(
                            onUnlockTap: () {
                               // Simple snackbar as MVP or callback if we had one.
                               // Ideally bubble up. For HF30 UI-only, default to mock.
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text("Upgrade to Elite to unlock accurate future projections."))
                               );
                            },
                            ctaLabel: "UNLOCK",
                            sigma: 6.0,
                         ),
                       ),
                       
                    // Legacy Lock (Full Lock) - Kept if needed, but blurFuture is partial.
                    if (widget.isLocked)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: AppColors.stateLocked,
                               borderRadius: BorderRadius.circular(4)
                             ),
                             child: const Text("LOCKED", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                          )
                        ),
                  ],
                );
              },
            ),
          ),
        );
      }
    );
  }
}


class _ChartPainter extends CustomPainter {
  final List<ChartCandle> past;
  final List<ChartCandle> future;
  final bool isLocked;
  final double animationValue;

  _ChartPainter({
    required this.past,
    required this.future,
    required this.isLocked,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Layout Logic
    // Screen split: 60% Past, 40% Future
    // We need to fit past candles in 60% width, future in 40%.
    // Or just distinct slots. Let's use fixed slots for simplicity.
    // Assuming standard view: 20 past, 10 future.
    
    // 1. Grid
    _drawGrid(canvas, size);

    // 2. Determine Scale (Min/Max Price)
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;
    
    for (var c in past) {
      if (c.l < minPrice) minPrice = c.l;
      if (c.h > maxPrice) maxPrice = c.h;
    }
    // Only verify future if not locked
    if (!isLocked) {
        for (var c in future) {
           if (c.l < minPrice) minPrice = c.l;
           if (c.h > maxPrice) maxPrice = c.h;
        }
    }
    
    // Safety check
    if (minPrice == double.infinity) {
        // Default range if no data valid
        minPrice = 0;
        maxPrice = 100;
    }
    
    final priceRange = maxPrice - minPrice;
    final padding = priceRange * 0.1; // 10% padding
    final yMin = minPrice - padding;
    final yMax = maxPrice + padding;
    final validYRange = yMax - yMin;

    double normalizeY(double price) {
        if (validYRange == 0) return size.height / 2;
        return size.height - ((price - yMin) / validYRange * size.height);
    }
    
    // 3. X-Axis Layout
    // We place "NOW" line at 66% width
    final nowX = size.width * 0.66;
    
    // Past Candles: equal spacing from 0 to nowX
    // Future Candles: equal spacing from nowX to width
    
    // Draw Past
    if (past.isNotEmpty) {
       final slotWidth = nowX / past.length;
       for (int i = 0; i < past.length; i++) {
          final x = i * slotWidth;
          _drawCandle(canvas, past[i], x, slotWidth * 0.8, normalizeY, isGhost: false);
       }
    }
    
    // Draw NOW Line
    final nowPaint = Paint()
       ..color = AppColors.neonCyan
       ..strokeWidth = 1.5;
       //..style = PaintingStyle.stroke; // Line is stroke by default
    
    // Dashed line or solid? Prompt says "central vertical line + small bright notch"
    canvas.drawLine(Offset(nowX, 0), Offset(nowX, size.height), nowPaint..color = AppColors.neonCyan.withValues(alpha:0.5));
    
    // Notch
    canvas.drawCircle(Offset(nowX, size.height), 3, Paint()..color = AppColors.neonCyan);

    // Draw Future (Ghost)
    if (!isLocked && future.isNotEmpty) {
        final futureWidth = size.width - nowX;
        final slotWidth = futureWidth / future.length;
        
        for (int i = 0; i < future.length; i++) {
           final x = nowX + (i * slotWidth);
           
           // Animation Logic: Sequential Reveal
           // animationValue (0..1). 
           // We want candles to fade in left-to-right.
           // Normalized index: i / total.
           final progress = i / future.length;
           
           // Simple opactiy curve
           // If anim > progress, show.
           
           // Reveal effect:
           // As anim goes 0->1, we reveal 0->N candles
           // Wait, controller repeats. That might be annoying.
           // Prompt: "Ghost candles appear sequentially... Must not block UI"
           
           // Let's use opacity modulation.
           // Fade factor based on distance from NOW and animation value.
           // Cycle: 2 seconds.
           
           double revealThreshold = animationValue; 
           // If we are repeating 0->1, we can reveal them.
           // To make it look "live", maybe we just keep them visible but "breathing"?
           // Let's stick to simple: Alpha based on index vs reveal.
           
           // Wait, "Ghost candles... sequential reveal" implies they appear one by one.
           // Let's assume they are fully visible (as ghosts) when revealed.
           
           if (progress <= revealThreshold) {
              _drawCandle(canvas, future[i], x, slotWidth * 0.8, normalizeY, isGhost: true, opacityOverride: 0.4);
           }
        }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
      final paint = Paint()
         ..color = AppColors.borderSubtle.withValues(alpha:0.1)
         ..strokeWidth = 1;
      
      // Horizontal
      for (double y = 0; y < size.height; y += 40) {
         canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
  }

  void _drawCandle(Canvas canvas, ChartCandle c, double x, double w, double Function(double) normalizeY, {required bool isGhost, double opacityOverride = 1.0}) {
      final yO = normalizeY(c.o);
      final yC = normalizeY(c.c);
      final yH = normalizeY(c.h);
      final yL = normalizeY(c.l);
      final cx = x + (w/2);

      final isBull = c.c >= c.o;
      final color = isBull ? AppColors.marketBull : AppColors.marketBear;
      
      double opacity = isGhost ? 0.3 : 1.0;
      if (isGhost) opacity = opacityOverride;

      final paint = Paint()
         ..color = color.withValues(alpha:opacity)
         ..style = PaintingStyle.fill;
         
      // Wick
      canvas.drawLine(Offset(cx, yH), Offset(cx, yL), paint..strokeWidth = 1);
      
      // Body
      final top = min(yO, yC);
      final bot = max(yO, yC);
      final h = max(1.0, bot - top);
      
      canvas.drawRect(Rect.fromLTWH(x, top, w, h), paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true; // Animate
}


class _GhostTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic Calibrating Pattern: Sine wave with decay
    final paint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha:0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerY = size.height / 2;
    
    path.moveTo(0, centerY);

    // Draw a deterministic "heartbeat" or "calibrating" sine wave
    for (double x = 0; x <= size.width; x++) {
       // Frequency varies slightly to look "alive" but is math-deterministic
       final normalizedX = x / size.width;
       final amplitude = 20.0 * (1 - normalizedX) * sin(normalizedX * pi * 8); 
       
       // Deterministic shape
       final y = centerY + amplitude;
       path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
