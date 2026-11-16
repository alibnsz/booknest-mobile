import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';

/// Accessible pill badge showing availability with both icon/dot and text.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final BookStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final isAvailable = status == BookStatus.available;
    final foreground = isAvailable ? colors.available : colors.borrowed;
    final background = isAvailable
        ? colors.availableSurface
        : colors.borrowedSurface;
    final label = isAvailable ? 'Available' : 'Borrowed';
    final icon = isAvailable
        ? Icons.check_circle_rounded
        : Icons.schedule_rounded;

    return Semantics(
      label: 'Status: $label',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 12 : 14, color: foreground),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
