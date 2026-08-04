import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

enum _MbButtonVariant { primary, secondary, ghost, danger }

class MbButton extends StatelessWidget {
  const MbButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  }) : _variant = _MbButtonVariant.primary;

  const MbButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  }) : _variant = _MbButtonVariant.secondary;

  const MbButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  }) : _variant = _MbButtonVariant.ghost;

  const MbButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  }) : _variant = _MbButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final _MbButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 8), Text(label)],
              )
            : Text(label);

    final btn = switch (_variant) {
      _MbButtonVariant.primary => ElevatedButton(
          onPressed: (isLoading || onPressed == null) ? null : onPressed,
          child: child,
        ),
      _MbButtonVariant.secondary => ElevatedButton(
          onPressed: (isLoading || onPressed == null) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandLight,
            foregroundColor: AppColors.brand,
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
          child: child,
        ),
      _MbButtonVariant.ghost => OutlinedButton(
          onPressed: (isLoading || onPressed == null) ? null : onPressed,
          child: child,
        ),
      _MbButtonVariant.danger => ElevatedButton(
          onPressed: (isLoading || onPressed == null) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFEF2F2),
            foregroundColor: AppColors.statusCritical,
            shadowColor: Colors.transparent,
            elevation: 0,
          ),
          child: child,
        ),
    };

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }
}
