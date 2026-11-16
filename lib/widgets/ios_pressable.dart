import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Native iOS tactile press feedback using spring scale, opacity, and haptics.
class IOSPressable extends StatefulWidget {
  const IOSPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.965,
    this.pressedOpacity = 0.72,
    this.enableHaptic = true,
    this.semanticLabel,
    this.isButton = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double pressedOpacity;
  final bool enableHaptic;
  final String? semanticLabel;
  final bool isButton;

  @override
  State<IOSPressable> createState() => _IOSPressableState();
}

class _IOSPressableState extends State<IOSPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    if (widget.enableHaptic) {
      HapticFeedback.selectionClick();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    Widget content = AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1.0,
      duration: Duration(milliseconds: _pressed ? 85 : 160),
      curve: _pressed ? Curves.easeOut : Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: !enabled ? 0.55 : (_pressed ? widget.pressedOpacity : 1.0),
        duration: Duration(milliseconds: _pressed ? 85 : 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    if (widget.semanticLabel != null) {
      content = Semantics(
        button: widget.isButton,
        enabled: enabled,
        label: widget.semanticLabel,
        child: content,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: enabled ? _handleTap : null,
      child: content,
    );
  }
}

/// Crisp iOS primary filled CTA button with zero Material ripple.
class IOSPrimaryButton extends StatelessWidget {
  const IOSPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final enabled = onPressed != null;
    final bg = enabled ? (backgroundColor ?? colors.ink) : colors.softSurface;
    final fg = enabled ? (foregroundColor ?? Colors.white) : colors.mutedText;

    return IOSPressable(
      onTap: onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      pressedScale: 0.975,
      pressedOpacity: 0.82,
      enableHaptic: false,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 52,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: enabled ? null : Border.all(color: colors.hairlineBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: fg),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crisp iOS bordered secondary button with zero Material ripple.
class IOSSecondaryButton extends StatelessWidget {
  const IOSSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return IOSPressable(
      onTap: onPressed,
      pressedScale: 0.975,
      pressedOpacity: 0.72,
      semanticLabel: label,
      child: Container(
        height: 50,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.hairlineBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: iconColor ?? colors.ink),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
