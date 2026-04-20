import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_constant.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double blur;
  final Widget child;
  final BorderRadius borderRadius;
  final Color? color;
  final Color borderColor;
  final double borderWidth;

  const GlassmorphicContainer({
    super.key,
    required this.blur,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppConstant.BORDER_RADIUS_MEDIUM)),
    this.color,
    this.borderColor = Colors.transparent,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? Theme.of(context).colorScheme.surface.withOpacity(0.2),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}