import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../routes/app_routes.dart';
import '../state/app_scope.dart';
import '../state/catalog_controller.dart';
import '../state/library_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/book_card.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/category_chips.dart';
import '../widgets/empty_state.dart';
import '../widgets/ios_pressable.dart';
import '../widgets/search_field.dart';

/// Main catalog tab with live search, sort sheet, editorial banner, and grid.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.bottomPadding = 28});

  final double bottomPadding;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final query = AppScope.read(context).catalog.query;
    if (_searchController.text != query) {
      _searchController.text = query;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters(CatalogController catalog) {
    _searchController.clear();
    catalog.clearFilters();
  }

  Future<void> _showSortSheet(CatalogController catalog) async {
    final selected = await showCupertinoModalPopup<CatalogSortOrder>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Sort Catalog'),
        message: const Text('Choose how books are ordered'),
        actions: [
          for (final order in CatalogSortOrder.values)
            CupertinoActionSheetAction(
              isDefaultAction: catalog.sortOrder == order,
              onPressed: () => Navigator.pop(sheetContext, order),
              child: Text(
                catalog.sortOrder == order ? '✓ ${order.label}' : order.label,
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (selected != null) {
      catalog.setSortOrder(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final catalog = scope.catalog;
    final cart = scope.cart;
    final library = scope.library;
    final colors = context.bookNestColors;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Discover',
              style: TextStyle(
                color: colors.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            Text(
              'Find your next read',
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: cart,
            builder: (_, _) => CartBadgeButton(
              count: cart.count,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([catalog, library]),
        builder: (context, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            child: switch (catalog.loadState) {
              CatalogLoadState.loading => const _LoadingView(
                key: ValueKey('loading'),
              ),
              CatalogLoadState.error => EmptyState(
                key: const ValueKey('error'),
                icon: Icons.cloud_off_rounded,
                iconColor: colors.danger,
                title: 'Could not load catalog',
                message:
                    catalog.errorMessage ?? 'Please check the bundled assets.',
                actionLabel: 'Retry',
                onAction: catalog.load,
              ),
              CatalogLoadState.ready => _CatalogReadyView(
                key: const ValueKey('ready'),
                catalog: catalog,
                library: library,
                searchController: _searchController,
                bottomPadding: widget.bottomPadding,
                onOpenSort: () => _showSortSheet(catalog),
                onClearFilters: () => _clearAllFilters(catalog),
              ),
            },
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 13),
          const SizedBox(height: 14),
          Text(
            'Loading library catalog...',
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogReadyView extends StatelessWidget {
  const _CatalogReadyView({
    super.key,
    required this.catalog,
    required this.library,
    required this.searchController,
    required this.bottomPadding,
    required this.onOpenSort,
    required this.onClearFilters,
  });

  final CatalogController catalog;
  final LibraryController library;
  final TextEditingController searchController;
  final double bottomPadding;
  final VoidCallback onOpenSort;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final filteredBooks = catalog.filteredBooks;
    final categories = catalog.categories;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width < 560
                ? 2
                : width < 760
                ? 3
                : 4;
            const horizontalPadding = 32.0;
            const spacing = 14.0;
            final tileWidth =
                (width - horizontalPadding - (crossAxisCount - 1) * spacing) /
                crossAxisCount;
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final mainAxisExtent =
                math.max(120.0, tileWidth * 0.98) +
                (112.0 * textScale.clamp(1.0, 2.2));
            final sortActive = catalog.sortOrder != CatalogSortOrder.featured;

            return CustomScrollView(
              key: const PageStorageKey<String>('home_catalog_scroll'),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchField(
                            controller: searchController,
                            onChanged: catalog.setQuery,
                            onSubmitted: library.addRecentSearch,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IOSPressable(
                          onTap: onOpenSort,
                          pressedScale: 0.92,
                          semanticLabel: 'Sort catalog',
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: sortActive
                                  ? colors.ink
                                  : colors.softSurface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sortActive
                                    ? colors.ink
                                    : colors.hairlineBorder,
                              ),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: sortActive ? Colors.white : colors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _LibraryBanner(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: CategoryChips(
                    categories: categories,
                    selected: catalog.selectedCategory,
                    onSelected: catalog.setCategory,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          'Catalog',
                          style: TextStyle(
                            color: colors.ink,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            key: ValueKey<int>(filteredBooks.length),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.softSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: colors.hairlineBorder),
                            ),
                            child: Text(
                              '${filteredBooks.length}',
                              style: TextStyle(
                                color: colors.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (catalog.hasActiveFilters &&
                            filteredBooks.isNotEmpty)
                          IOSPressable(
                            onTap: onClearFilters,
                            semanticLabel: 'Clear filters',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Text(
                                'Clear filters',
                                style: TextStyle(
                                  color: colors.accent,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (filteredBooks.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: bottomPadding),
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No books match your search',
                        message: 'Try a different title, author name, or reset the active category filter.',
                        actionLabel: 'Clear filters',
                        onAction: onClearFilters,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 2, 16, bottomPadding),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        mainAxisExtent: mainAxisExtent,
                      ),
                      itemCount: filteredBooks.length,
                      itemBuilder: (context, index) {
                        final Book book = filteredBooks[index];
                        return BookCard(
                          book: book,
                          isSaved: library.isSaved(book.id),
                          onToggleSaved: () => library.toggleSaved(book.id),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.book,
                            arguments: book,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LibraryBanner extends StatelessWidget {
  const _LibraryBanner();

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Semantics(
      image: true,
      label: 'BookNest Library curated collection banner',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.hairlineBorder),
          color: const Color(0xFFF3F4F6),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bannerHeight = math.min(
              176.0,
              constraints.maxWidth * (460 / 1200),
            );
            return SizedBox(
              width: double.infinity,
              height: bannerHeight,
              child: Image.asset(
                'assets/images/banner.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  padding: const EdgeInsets.all(20),
                  color: colors.softSurface,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'BookNest Library',
                              style: TextStyle(
                                color: colors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Browse available titles and build your borrow basket.',
                              style: TextStyle(
                                color: colors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.menu_book_rounded,
                        size: 40,
                        color: colors.accent,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
