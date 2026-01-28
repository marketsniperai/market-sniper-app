import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class BreathingStatusAccent extends StatefulWidget {
  final Color color;
  final bool active;

  const BreathingStatusAccent({
    super.key,
    required this.color,
    this.active = true,
  });

  @override
  State<BreathingStatusAccent> createState() => _BreathingStatusAccentState();
}

class _BreathingStatusAccentState extends State<BreathingStatusAccent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Subtle breathing curve
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _opacityAnim = Tween<double>(begin: 0.6, end: 1.0).animate(curve);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(curve);

    if (widget.active) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BreathingStatusAccent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      if (widget.active) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.6; // Idle state
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If neutral/disabled, show static dot
    if (!widget.active) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.5),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 6 * _scaleAnim.value,
          height: 6 * _scaleAnim.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_opacityAnim.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.5 * _opacityAnim.value),
                blurRadius: 4 * _scaleAnim.value,
                spreadRadius: 1,
              )
            ],
          ),
        );
      },
    );
  }
}
