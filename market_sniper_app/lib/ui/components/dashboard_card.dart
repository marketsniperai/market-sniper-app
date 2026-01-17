import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../tokens/dashboard_spacing.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;

  const DashboardCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? DashboardSpacing.cardMargin,
      padding: padding ?? DashboardSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface1,
        borderRadius: BorderRadius.circular(DashboardSpacing.cornerRadius),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: DashboardSpacing.borderWidth,
        ),
      ),
      child: child,
    );
  }
}
