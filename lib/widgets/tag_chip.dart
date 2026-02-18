import 'package:flutter/material.dart';
import '../models/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isSmall;

  const TagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 6 : 10,
          vertical: isSmall ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: tag.colorValue.withValues(alpha: isSelected ? 0.3 : 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tag.colorValue.withValues(alpha: isSelected ? 0.6 : 0.3),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isSmall ? 6 : 8,
              height: isSmall ? 6 : 8,
              decoration: BoxDecoration(
                color: tag.colorValue,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isSmall ? 4 : 6),
            Text(
              tag.name,
              style: TextStyle(
                color: tag.colorValue,
                fontSize: isSmall ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.close,
                  size: isSmall ? 12 : 14,
                  color: tag.colorValue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
