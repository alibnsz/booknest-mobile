import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/ios_pressable.dart';

/// Friendly fallback screen shown for unknown routes or missing arguments.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({
    super.key,
    this.message = 'The page you requested does not exist.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Center(
          child: IOSPressable(
            onTap: () => Navigator.maybePop(context),
            pressedScale: 0.88,
            semanticLabel: 'Back',
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: colors.ink,
              ),
            ),
          ),
        ),
        title: const Text('BookNest'),
      ),
      body: EmptyState(
        icon: Icons.explore_off_rounded,
        title: 'Page not found',
        message: message,
        actionLabel: 'Back to catalog',
        onAction: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
      ),
    );
  }
}
