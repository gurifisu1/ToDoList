import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blur = 10,
    this.color,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color ?? AppTheme.glassWhite,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(color: AppTheme.glassBorder, width: 0.5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (color ?? AppTheme.glassWhite)
                          .withValues(alpha: 0.15),
                      (color ?? AppTheme.glassWhite)
                          .withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
