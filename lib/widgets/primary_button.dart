import 'package:flutter/material.dart';

/// HomiQ Reusable Primary Button
/// Encapsulates consistent design, accessibility standards (HCI targets),
/// and loading state support.
class PrimaryButton extends StatelessWidget {
  /// The label text displayed on the button.
  final String text;

  /// Callback when the button is tapped. Pass null to disable the button.
  final VoidCallback? onPressed;

  /// Shows a circular progress indicator instead of the text/icon.
  final bool isLoading;

  /// Optional prefix icon to display beside the text.
  final IconData? icon;

  /// Optional background color override. Defaults to primaryBlue.
  final Color? backgroundColor;

  /// Optional text/icon color override. Defaults to surface (white).
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = theme.elevatedButtonTheme.style;

    // Apply color overrides if provided, otherwise fallback to theme configurations
    final effectiveStyle = buttonStyle?.copyWith(
      backgroundColor: backgroundColor != null
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.onSurface.withAlpha(31); // 12% opacity
              }
              return backgroundColor;
            })
          : null,
      foregroundColor: textColor != null
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return theme.colorScheme.onSurface.withAlpha(97); // 38% opacity
              }
              return textColor;
            })
          : null,
    );

    // Disable interactions if loading
    final effectiveOnPressed = (isLoading || onPressed == null) ? null : onPressed;

    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          color: textColor ?? theme.colorScheme.onPrimary,
        ),
      );
    } else {
      if (icon != null) {
        buttonChild = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(text),
          ],
        );
      } else {
        buttonChild = Text(text);
      }
    }

    return Semantics(
      button: true,
      enabled: effectiveOnPressed != null,
      label: text,
      child: ElevatedButton(
        style: effectiveStyle,
        onPressed: effectiveOnPressed,
        child: buttonChild,
      ),
    );
  }
}
