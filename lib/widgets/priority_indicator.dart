import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriorityIndicator extends StatelessWidget {
  final int priority;
  final double size;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (priority == 0) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.getPriorityColor(priority),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.getPriorityColor(priority).withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
