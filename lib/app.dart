import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/asset_book_repository.dart';
import 'data/book_repository.dart';
import 'routes/app_routes.dart';
import 'state/app_scope.dart';
import 'state/cart_controller.dart';
import 'state/catalog_controller.dart';
import 'state/library_controller.dart';
import 'theme/app_theme.dart';

/// Global scroll behavior enforcing iOS rubber-band bounce physics.
class _NativeIOSScrollBehavior extends MaterialScrollBehavior {
  const _NativeIOSScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

/// Root widget wiring dependency injection, always-white iOS theme, and routing.
class BookNestApp extends StatefulWidget {
  const BookNestApp({super.key, this.repository});

  /// Optional repository override for testing or future HTTP integration.
  final BookRepository? repository;

  @override
  State<BookNestApp> createState() => _BookNestAppState();
}

class _BookNestAppState extends State<BookNestApp> {
  late final CatalogController _catalog;
  late final CartController _cart;
  late final LibraryController _library;

  @override
  void initState() {
    super.initState();
    _catalog = CatalogController(
      repository: widget.repository ?? AssetBookRepository(),
    );
    _cart = CartController(catalog: _catalog);
    _library = LibraryController(catalog: _catalog);
    _catalog.load();
  }

  @override
  void dispose() {
    _library.dispose();
    _cart.dispose();
    _catalog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AppScope(
        catalog: _catalog,
        cart: _cart,
        library: _library,
        child: MaterialApp(
          title: 'BookNest',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          themeMode: ThemeMode.light,
          scrollBehavior: const _NativeIOSScrollBehavior(),
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          onUnknownRoute: AppRoutes.onUnknownRoute,
        ),
      ),
    );
  }
}
