import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/book_filters.dart';
import 'ios_pressable.dart';

/// Horizontal scrollable single-select category pill bar.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.toLowerCase() == selected.toLowerCase();
          final label = formatCategoryLabel(category);

          return Center(
            child: Semantics(
              selected: isSelected,
              child: IOSPressable(
                onTap: () => onSelected(category),
                pressedScale: 0.94,
                semanticLabel: '$label category',
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.chipSelectedBg
                          : colors.cardSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? colors.chipSelectedBg
                            : colors.hairlineBorder,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? colors.chipSelectedFg : colors.ink,
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
