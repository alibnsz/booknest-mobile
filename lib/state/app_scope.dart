import 'package:flutter/widgets.dart';

import 'cart_controller.dart';
import 'catalog_controller.dart';
import 'library_controller.dart';

/// Provides controllers down the widget tree using SDK-only mechanisms.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.catalog,
    required this.cart,
    required this.library,
    required super.child,
  });

  final CatalogController catalog;
  final CartController cart;
  final LibraryController library;

  /// Subscribes to [AppScope] changes and returns the nearest instance.
  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context.');
    return scope!;
  }

  /// Reads the nearest [AppScope] without registering a widget dependency.
  static AppScope read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return catalog != oldWidget.catalog ||
        cart != oldWidget.cart ||
        library != oldWidget.library;
  }
}
