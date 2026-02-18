import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isSmall;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 12 : 20,
                vertical: isSmall ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
                border: Border.all(
                  color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: isSmall ? 16 : 20,
                        color: color ?? AppTheme.primaryColor),
                    SizedBox(width: isSmall ? 4 : 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: color ?? AppTheme.primaryColor,
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
