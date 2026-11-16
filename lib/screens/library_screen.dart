import 'dart:math' as math;

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
import '../widgets/empty_state.dart';
import '../widgets/ios_pressable.dart';
import '../widgets/reading_progress_sheet.dart';
import '../widgets/status_badge.dart';

/// Filter options for the personal Library tab.
enum LibraryFilter {
  all('All'),
  saved('Saved'),
  reading('Reading'),
  borrowed('Borrowed'),
  finished('Finished');

  const LibraryFilter(this.label);
  final String label;
}

/// Personal library screen showing saved bookmarks, reading progress, and loans.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.filterNotifier,
    required this.onBrowseCatalog,
    this.bottomPadding = 104,
  });

  final ValueNotifier<LibraryFilter> filterNotifier;
  final VoidCallback onBrowseCatalog;
  final double bottomPadding;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  void _openBook(Book book) {
    Navigator.pushNamed(context, AppRoutes.book, arguments: book);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final catalog = scope.catalog;
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
              'My Library',
              style: TextStyle(
                color: colors.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            Text(
              'Saved, reading & borrowed books',
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<LibraryFilter>(
        valueListenable: widget.filterNotifier,
        builder: (context, selectedFilter, _) {
          return ListenableBuilder(
            listenable: Listenable.merge([catalog, library]),
            builder: (context, _) {
              if (catalog.loadState == CatalogLoadState.loading) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 13),
                );
              }
              if (catalog.loadState == CatalogLoadState.error) {
                return EmptyState(
                  icon: Icons.cloud_off_rounded,
                  iconColor: colors.danger,
                  title: 'Could not load library',
                  message: catalog.errorMessage ?? 'Try loading again.',
                  actionLabel: 'Retry',
                  onAction: catalog.load,
                );
              }

              final saved = library.savedBooks;
              final reading = library.readingBooks;
              final borrowed = library.borrowedBooks;
              final finished = library.finishedBooks;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: CustomScrollView(
                    key: const PageStorageKey<String>('library_scroll'),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: LibraryFilter.values.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final filter = LibraryFilter.values[index];
                              final active = filter == selectedFilter;
                              return Center(
                                child: IOSPressable(
                                  onTap: () =>
                                      widget.filterNotifier.value = filter,
                                  pressedScale: 0.94,
                                  semanticLabel: '${filter.label} filter',
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 17,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? colors.chipSelectedBg
                                          : colors.cardSurface,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: active
                                            ? colors.chipSelectedBg
                                            : colors.hairlineBorder,
                                      ),
                                    ),
                                    child: Text(
                                      filter.label,
                                      style: TextStyle(
                                        color: active
                                            ? colors.chipSelectedFg
                                            : colors.ink,
                                        fontSize: 13.5,
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (selectedFilter == LibraryFilter.all) ...[
                        ..._buildAllSections(
                          context,
                          catalog: catalog,
                          library: library,
                          saved: saved,
                          reading: reading,
                          borrowed: borrowed,
                          finished: finished,
                        ),
                      ] else ...[
                        ..._buildFilteredList(
                          context,
                          filter: selectedFilter,
                          library: library,
                          books: switch (selectedFilter) {
                            LibraryFilter.saved => saved,
                            LibraryFilter.reading => reading,
                            LibraryFilter.borrowed => borrowed,
                            LibraryFilter.finished => finished,
                            LibraryFilter.all => const <Book>[],
                          },
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: SizedBox(height: widget.bottomPadding),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildAllSections(
    BuildContext context, {
    required CatalogController catalog,
    required LibraryController library,
    required List<Book> saved,
    required List<Book> reading,
    required List<Book> borrowed,
    required List<Book> finished,
  }) {
    final softwareAndDesign = catalog.books
        .where((b) => b.category == 'software' || b.category == 'design')
        .take(3)
        .toList(growable: false);
    final fictionPicks = catalog.books
        .where((b) => b.category == 'novel' || b.category == 'sci-fi')
        .take(3)
        .toList(growable: false);

    return [
      if (softwareAndDesign.length >= 3 || fictionPicks.length >= 3)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Curated Shelves',
                  trailingLabel: 'Browse all',
                  onTrailingTap: widget.onBrowseCatalog,
                ),
                const SizedBox(height: 10),
                if (softwareAndDesign.length >= 3)
                  _CuratedShelfCard(
                    title: 'Design & Craft',
                    subtitle: 'Systems, interfaces, and engineering habits.',
                    badgeLeft: 'Curated',
                    badgeRight: '${softwareAndDesign.length} books',
                    books: softwareAndDesign,
                    onTap: () => _openBook(softwareAndDesign.first),
                  ),
                if (softwareAndDesign.length >= 3 && fictionPicks.length >= 3)
                  const SizedBox(height: 12),
                if (fictionPicks.length >= 3)
                  _CuratedShelfCard(
                    title: 'Stories & Worlds',
                    subtitle:
                        'Classic novels and timeless speculative fiction.',
                    badgeLeft: 'Popular',
                    badgeRight: '${fictionPicks.length} books',
                    books: fictionPicks,
                    onTap: () => _openBook(fictionPicks.first),
                  ),
              ],
            ),
          ),
        ),
      if (reading.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SectionHeader(
              title: 'Currently Reading',
              count: reading.length,
              trailingLabel: 'See all',
              onTrailingTap: () =>
                  widget.filterNotifier.value = LibraryFilter.reading,
            ),
          ),
        ),
        _buildBookCardSliver(reading, library),
      ],
      if (saved.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SectionHeader(
              title: 'Saved Books',
              count: saved.length,
              trailingLabel: 'See all',
              onTrailingTap: () =>
                  widget.filterNotifier.value = LibraryFilter.saved,
            ),
          ),
        ),
        _buildBookCardSliver(saved, library),
      ],
      if (borrowed.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SectionHeader(
              title: 'Borrowed',
              count: borrowed.length,
              trailingLabel: 'See all',
              onTrailingTap: () =>
                  widget.filterNotifier.value = LibraryFilter.borrowed,
            ),
          ),
        ),
        _buildBookCardSliver(borrowed, library),
      ],
      if (finished.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SectionHeader(
              title: 'Finished',
              count: finished.length,
              trailingLabel: 'See all',
              onTrailingTap: () =>
                  widget.filterNotifier.value = LibraryFilter.finished,
            ),
          ),
        ),
        _buildBookCardSliver(finished, library),
      ],
    ];
  }

  List<Widget> _buildFilteredList(
    BuildContext context, {
    required LibraryFilter filter,
    required LibraryController library,
    required List<Book> books,
  }) {
    if (books.isEmpty) {
      final (icon, title, message) = switch (filter) {
        LibraryFilter.saved => (
          Icons.bookmark_border_rounded,
          'No saved books yet',
          'Tap the bookmark icon on any book to save it here for later.',
        ),
        LibraryFilter.reading => (
          Icons.menu_book_rounded,
          'Not reading anything right now',
          'Open any book and set its status to Reading to track your pages.',
        ),
        LibraryFilter.borrowed => (
          Icons.shopping_basket_outlined,
          'No borrowed books',
          'Books you confirm from the borrow basket will appear here.',
        ),
        LibraryFilter.finished => (
          Icons.verified_outlined,
          'No finished books yet',
          'Mark a book as Finished once you complete reading it.',
        ),
        LibraryFilter.all => (
          Icons.library_books_outlined,
          'Your library is empty',
          'Browse the catalog to start saving and reading books.',
        ),
      };

      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: icon,
            title: title,
            message: message,
            actionLabel: 'Browse catalog',
            onAction: widget.onBrowseCatalog,
          ),
        ),
      ];
    }

    return [
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
      _buildBookCardSliver(books, library),
    ];
  }

  Widget _buildBookCardSliver(List<Book> books, LibraryController library) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.separated(
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final book = books[index];
          return _LibraryBookItem(
            book: book,
            entry: library.entryFor(book.id),
            isSaved: library.isSaved(book.id),
            onTap: () => _openBook(book),
            onToggleSaved: () => library.toggleSaved(book.id),
            onUpdateProgress: () => showReadingProgressSheet(context, book),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.count,
    this.trailingLabel,
    this.onTrailingTap,
  });

  final String title;
  final int? count;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.softSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.hairlineBorder),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (trailingLabel != null && onTrailingTap != null)
          IOSPressable(
            onTap: onTrailingTap,
            semanticLabel: trailingLabel,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                trailingLabel!,
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CuratedShelfCard extends StatelessWidget {
  const _CuratedShelfCard({
    required this.title,
    required this.subtitle,
    required this.badgeLeft,
    required this.badgeRight,
    required this.books,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badgeLeft;
  final String badgeRight;
  final List<Book> books;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return IOSPressable(
      onTap: onTap,
      pressedScale: 0.975,
      semanticLabel: '$title shelf',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        decoration: BoxDecoration(
          color: colors.softSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.hairlineBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniShelfPill(
                  icon: Icons.auto_awesome_rounded,
                  label: badgeLeft,
                ),
                _MiniShelfPill(
                  icon: Icons.menu_book_rounded,
                  label: badgeRight,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.mutedText, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 106,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    left: 36,
                    bottom: -14,
                    child: Transform.rotate(
                      angle: -8 * math.pi / 180,
                      child: SizedBox(
                        width: 78,
                        child: BookCover(
                          book: books[0],
                          borderRadius: 10,
                          compact: true,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 36,
                    bottom: -14,
                    child: Transform.rotate(
                      angle: 8 * math.pi / 180,
                      child: SizedBox(
                        width: 78,
                        child: BookCover(
                          book: books[2],
                          borderRadius: 10,
                          compact: true,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    child: SizedBox(
                      width: 84,
                      child: BookCover(
                        book: books[1],
                        borderRadius: 10,
                        compact: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniShelfPill extends StatelessWidget {
  const _MiniShelfPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.hairlineBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryBookItem extends StatelessWidget {
  const _LibraryBookItem({
    required this.book,
    required this.entry,
    required this.isSaved,
    required this.onTap,
    required this.onToggleSaved,
    required this.onUpdateProgress,
  });

  final Book book;
  final ReadingEntry? entry;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onToggleSaved;
  final VoidCallback onUpdateProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final isReading = entry?.status == ReadingStatus.reading;
    final isFinished = entry?.status == ReadingStatus.finished;
    final totalPages = book.pageCount;
    final progressRatio = isReading && totalPages != null && totalPages > 0
        ? (entry!.currentPage / totalPages).clamp(0.0, 1.0)
        : null;

    return IOSPressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: '${book.title} by ${book.author}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.hairlineBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Hero(
                tag: 'book-cover-${book.id}',
                child: BookCover(book: book, borderRadius: 9, compact: true),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.ink,
                                fontSize: 15,
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
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IOSPressable(
                        onTap: onToggleSaved,
                        pressedScale: 0.85,
                        semanticLabel: isSaved
                            ? 'Remove bookmark'
                            : 'Save book',
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: isSaved ? colors.ink : colors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      StatusBadge(status: book.status, compact: true),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.softSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          formatCategoryLabel(book.category),
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isFinished)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.availableSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Finished',
                            style: TextStyle(
                              color: colors.available,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isReading) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progressRatio ?? 0.35,
                              minHeight: 6,
                              backgroundColor: colors.softSurface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colors.accent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IOSPressable(
                          onTap: onUpdateProgress,
                          pressedScale: 0.94,
                          semanticLabel: 'Update reading progress',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.softSurface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: colors.hairlineBorder),
                            ),
                            child: Text(
                              totalPages != null
                                  ? '${entry!.currentPage}/$totalPages p'
                                  : 'Page ${entry!.currentPage}',
                              style: TextStyle(
                                color: colors.ink,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
