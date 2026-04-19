import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ??
        (isDark ? AppColors.darkSurface : AppColors.surface);
    final borderColor = isDark ? AppColors.darkDivider : AppColors.divider;

    final card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusLg),
        border: border ??
            Border.all(color: borderColor, width: 1),
      ),
      padding:
          padding ?? const EdgeInsets.all(AppDimensions.cardPadding),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppDimensions.radiusLg),
          child: card,
        ),
      );
    }

    return card;
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.colors,
    this.padding,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusLg),
      ),
      padding:
          padding ?? const EdgeInsets.all(AppDimensions.cardPaddingLg),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ?? BorderRadius.circular(AppDimensions.radiusLg),
          child: content,
        ),
      );
    }
    return content;
  }
}
