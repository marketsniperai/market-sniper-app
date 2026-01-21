import 'package:flutter/material.dart';

/// A scroll container that enforces the "Global Scroll Law":
/// 1. Content is always scrollable (SingleChildScrollView).
/// 2. Content always takes at least the full height of the parent (ConstrainedBox).
/// 3. Accepts an optional [ScrollController] (crucial for DraggableScrollableSheet).
class CanonicalScrollContainer extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const CanonicalScrollContainer({
    super.key,
    required this.child,
    this.controller,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: controller,
          physics: physics ?? const AlwaysScrollableScrollPhysics(),
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
