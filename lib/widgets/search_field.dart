import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ios_pressable.dart';

/// Pill-shaped live search input with an animated clear button.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.hintText = 'Search books, authors, genres...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.isNotEmpty;

        return TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            color: colors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Icon(
                Icons.search_rounded,
                color: colors.mutedText,
                size: 21,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: hasText
                  ? IOSPressable(
                      key: const ValueKey('clear_search'),
                      semanticLabel: 'Clear search',
                      pressedScale: 0.85,
                      onTap: () {
                        controller.clear();
                        onChanged('');
                        onClear?.call();
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: colors.mutedText.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: colors.ink,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty_suffix')),
            ),
          ),
        );
      },
    );
  }
}
