import 'package:flutter/material.dart';

/// HomiQ App Logo Widget
/// A reusable logo component with customizable size and box fit.
class AppLogo extends StatelessWidget {
  /// Width of the logo. If null, it will resize proportionally based on height.
  final double? width;

  /// Height of the logo. If null, it will resize proportionally based on width.
  final double? height;

  /// How the logo image should fit its container.
  final BoxFit fit;

  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logos/homiq_logo.png',
      width: width,
      height: height,
      fit: fit,
      // Provide accessibility semantic labeling for screen readers
      semanticLabel: 'HomiQ App Logo',
      // If error occurs, render a fallback placeholder gracefully
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.home_repair_service_rounded,
          size: height ?? width ?? 48,
          color: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }
}
