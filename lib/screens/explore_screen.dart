import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../routes/app_routes.dart';
import '../state/app_scope.dart';
import '../state/catalog_controller.dart';
import '../state/library_controller.dart';
import '../theme/app_theme.dart';
import '../utils/book_filters.dart';
import '../widgets/book_cover.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/ios_pressable.dart';
import '../widgets/search_field.dart';
import '../widgets/status_badge.dart';

/// Editorial discovery screen with recent searches, trending shelf, and categories.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.onSelectCategoryInCatalog,
    this.bottomPadding = 104,
  });

  final ValueChanged<String> onSelectCategoryInCatalog;
  final double bottomPadding;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _searchController;
  String _localQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyRecentSearch(String term, LibraryController library) {
    _searchController.text = term;
    _searchController.selection = TextSelection.collapsed(offset: term.length);
    setState(() => _localQuery = term);
    library.addRecentSearch(term);
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
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Text(
          'Explore',
          style: TextStyle(
            color: colors.ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
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
          if (catalog.loadState == CatalogLoadState.loading) {
            return const Center(child: CupertinoActivityIndicator(radius: 13));
          }
          if (catalog.loadState == CatalogLoadState.error) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              iconColor: colors.danger,
              title: 'Could not load catalog',
              message: catalog.errorMessage ?? 'Try loading again.',
              actionLabel: 'Retry',
              onAction: catalog.load,
            );
          }

          final books = catalog.books;
          final isSearching = _localQuery.trim().isNotEmpty;
          final searchResults = filterBooks(books, query: _localQuery);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: CustomScrollView(
                key: const PageStorageKey<String>('explore_scroll'),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: SearchField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _localQuery = value),
                        onSubmitted: library.addRecentSearch,
                        onClear: () => setState(() => _localQuery = ''),
                      ),
                    ),
                  ),
                  if (isSearching)
                    ..._buildSearchSlivers(context, searchResults, library)
                  else
                    ..._buildEditorialSlivers(context, books, library),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSearchSlivers(
    BuildContext context,
    List<Book> results,
    LibraryController library,
  ) {
    final colors = context.bookNestColors;

    if (results.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matching books',
              message: 'No books or authors matched "$_localQuery".',
              actionLabel: 'Clear search',
              onAction: () {
                _searchController.clear();
                setState(() => _localQuery = '');
              },
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            '${results.length} ${results.length == 1 ? 'result' : 'results'}',
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomPadding),
        sliver: SliverList.separated(
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final book = results[index];
            return _ExploreListTile(
              book: book,
              isSaved: library.isSaved(book.id),
              onToggleSaved: () => library.toggleSaved(book.id),
              onTap: () {
                library.addRecentSearch(_localQuery);
                Navigator.pushNamed(context, AppRoutes.book, arguments: book);
              },
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildEditorialSlivers(
    BuildContext context,
    List<Book> books,
    LibraryController library,
  ) {
    final colors = context.bookNestColors;
    final recent = library.recentSearches;
    final trending = books.take(6).toList(growable: false);
    final categoryKeys = extractCategories(books)
        .where((c) => c != allCategoriesKey)
        .toList(growable: false);

    return [
      if (recent.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Recent Search',
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    IOSPressable(
                      onTap: library.clearRecentSearches,
                      semanticLabel: 'Clear all recent searches',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final term in recent)
                      _RecentSearchChip(
                        label: term,
                        onTap: () => _applyRecentSearch(term, library),
                        onRemove: () => library.removeRecentSearch(term),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.softSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 15,
                  color: colors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Trending ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'This Week',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IOSPressable(
                onTap: () => widget.onSelectCategoryInCatalog(allCategoriesKey),
                semanticLabel: 'View all trending books',
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 256,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: trending.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = trending[index];
              return _TrendingBookCard(
                book: book,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.book,
                  arguments: book,
                ),
              );
            },
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.softSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 15,
                  color: colors.ink,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Explore ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text: 'by Categories',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categoryKeys.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = categoryKeys[index];
              final categoryBooks = filterBooks(books, category: category);
              final leadBook = categoryBooks.first;
              return _CategoryShowcaseCard(
                category: category,
                leadBook: leadBook,
                count: categoryBooks.length,
                onTap: () => widget.onSelectCategoryInCatalog(category),
              );
            },
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: widget.bottomPadding)),
    ];
  }
}

class _RecentSearchChip extends StatelessWidget {
  const _RecentSearchChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.hairlineBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IOSPressable(
            onTap: onTap,
            pressedScale: 0.95,
            semanticLabel: 'Search $label',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 6, 9),
              child: Text(
                label,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          IOSPressable(
            onTap: onRemove,
            pressedScale: 0.85,
            semanticLabel: 'Remove $label from recent searches',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 9, 12, 9),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: colors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingBookCard extends StatelessWidget {
  const _TrendingBookCard({required this.book, required this.onTap});

  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return SizedBox(
      width: 136,
      child: IOSPressable(
        onTap: onTap,
        pressedScale: 0.96,
        semanticLabel: '${book.title} by ${book.author}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 184,
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.softSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.hairlineBorder),
              ),
              child: Center(
                child: Hero(
                  tag: 'book-cover-${book.id}',
                  child: BookCover(book: book, borderRadius: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryShowcaseCard extends StatelessWidget {
  const _CategoryShowcaseCard({
    required this.category,
    required this.leadBook,
    required this.count,
    required this.onTap,
  });

  final String category;
  final Book leadBook;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final label = formatCategoryLabel(category);

    return SizedBox(
      width: 124,
      child: IOSPressable(
        onTap: onTap,
        pressedScale: 0.96,
        semanticLabel: '$label category, $count books',
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.hairlineBorder),
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.softSurface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: BookCover(
                      book: leadBook,
                      borderRadius: 8,
                      compact: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'book' : 'books'}',
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreListTile extends StatelessWidget {
  const _ExploreListTile({
    required this.book,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onTap,
  });

  final Book book;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return IOSPressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: '${book.title} by ${book.author}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.hairlineBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Hero(
                tag: 'book-cover-${book.id}',
                child: BookCover(book: book, borderRadius: 8, compact: true),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedText, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: book.status, compact: true),
                ],
              ),
            ),
            IOSPressable(
              onTap: onToggleSaved,
              pressedScale: 0.85,
              semanticLabel: isSaved ? 'Remove bookmark' : 'Save book',
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 21,
                  color: isSaved ? colors.ink : colors.mutedText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
