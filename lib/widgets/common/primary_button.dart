import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? icon;
  final double? height;
  final Color? color;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.height,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? AppDimensions.buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primaryLight.withOpacity(0.5),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final double? height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? AppDimensions.buttonHeight,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

class SmallChipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final Color? selectedColor;

  const SmallChipButton({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (selectedColor ?? AppColors.primary)
              : (isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant),
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected
                ? (selectedColor ?? AppColors.primary)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w500,
              ),
        ),
      ),
    );
  }
}
