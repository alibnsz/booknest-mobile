import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ios_pressable.dart';

/// AppBar basket button displaying an animated item count badge.
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: IOSPressable(
        onTap: onPressed,
        pressedScale: 0.90,
        semanticLabel: 'Borrow basket, $count ${count == 1 ? 'item' : 'items'}',
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.softSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.hairlineBorder),
                ),
                child: Icon(
                  Icons.shopping_basket_outlined,
                  size: 19,
                  color: colors.ink,
                ),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: count > 0
                      ? Container(
                          key: ValueKey<int>(count),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.canvas,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.0,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey<int>(0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
