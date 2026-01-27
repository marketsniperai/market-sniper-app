import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Observer to track if we can pop
class GlobalBackOverlayObserver extends NavigatorObserver {
  final ValueNotifier<bool> canPopNotifier = ValueNotifier(false);

  @override
  void didPush(Route route, Route? previousRoute) => _update();
  @override
  void didPop(Route route, Route? previousRoute) => _update();
  @override
  void didRemove(Route route, Route? previousRoute) => _update();
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => _update();

  void _update() {
    // Schedule post-frame to avoid setState during build or race conditions
    // Using navigator key might be safer if we have access, but observer has 'navigator' property.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator != null) {
        canPopNotifier.value = navigator!.canPop();
      }
    });
  }
}

class GlobalBackOverlay extends StatelessWidget {
  final Widget child;
  final GlobalBackOverlayObserver observer;

  const GlobalBackOverlay({
    super.key,
    required this.child,
    required this.observer,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // App Content
        child,

        // Overlay
        ValueListenableBuilder<bool>(
          valueListenable: observer.canPopNotifier,
          builder: (context, canPop, _) {
            if (!canPop) return const SizedBox.shrink();

            return Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () {
                      // Use navigator from observer or global key
                      if (observer.navigator?.canPop() ?? false) {
                        observer.navigator?.pop();
                      }
                    },
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left,
                        color: AppColors.neonCyan,
                        size: 32, // Subtle but visible
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
