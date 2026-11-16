import 'package:flutter/cupertino.dart';

import '../models/book.dart';
import '../screens/book_detail_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/not_found_screen.dart';

/// Named route identifiers used across BookNest Mobile.
abstract final class AppRoutes {
  static const String home = '/';
  static const String book = '/book';
  static const String cart = '/cart';

  /// Resolves named routes using native iOS [CupertinoPageRoute] transitions.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const MainShellScreen(),
        );
      case book:
        final args = settings.arguments;
        if (args is! Book) {
          return CupertinoPageRoute<void>(
            settings: settings,
            builder: (_) => const NotFoundScreen(
              message: 'We could not find the requested book details.',
            ),
          );
        }
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const BookDetailScreen(),
        );
      case cart:
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const CartScreen(),
        );
      default:
        return CupertinoPageRoute<void>(
          settings: settings,
          builder: (_) => const NotFoundScreen(),
        );
    }
  }

  /// Fallback handler for unrecognized route names.
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return CupertinoPageRoute<void>(
      settings: settings,
      builder: (_) => const NotFoundScreen(),
    );
  }
}
