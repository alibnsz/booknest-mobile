import 'package:flutter/material.dart';

import '../models/book.dart';
import '../routes/app_routes.dart';
import '../state/app_scope.dart';
import '../state/cart_controller.dart';
import '../state/library_controller.dart';
import '../theme/app_theme.dart';
import '../utils/book_filters.dart';
import '../widgets/book_cover.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/ios_pressable.dart';
import '../widgets/reading_progress_sheet.dart';
import '../widgets/status_badge.dart';
import 'not_found_screen.dart';

/// Displays full details, reading tracker, and lending actions for a [Book].
class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, this.initialBook});

  final Book? initialBook;

  void _openCart(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.pushNamed(context, AppRoutes.cart);
  }

  @override
  Widget build(BuildContext context) {
    final routeArg = initialBook ?? ModalRoute.of(context)?.settings.arguments;
    if (routeArg is! Book) {
      return const NotFoundScreen(
        message: 'We could not find the requested book details.',
      );
    }

    final scope = AppScope.of(context);
    final catalog = scope.catalog;
    final cart = scope.cart;
    final library = scope.library;
    final colors = context.bookNestColors;

    return ListenableBuilder(
      listenable: Listenable.merge([catalog, cart, library]),
      builder: (context, _) {
        final book = catalog.findById(routeArg.id) ?? routeArg;
        final isInCart = cart.contains(book.id);
        final isSaved = library.isSaved(book.id);
        final entry = library.entryFor(book.id);
        final readingStatus = entry?.status ?? ReadingStatus.none;

        return Scaffold(
          appBar: AppBar(
            leadingWidth: 56,
            leading: Center(
              child: IOSPressable(
                onTap: () => Navigator.pop(context),
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
            actions: [
              IOSPressable(
                onTap: () => library.toggleSaved(book.id),
                pressedScale: 0.88,
                semanticLabel: isSaved ? 'Remove bookmark' : 'Save book',
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: isSaved ? colors.ink : colors.softSurface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSaved ? colors.ink : colors.hairlineBorder,
                    ),
                  ),
                  child: Icon(
                    isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 19,
                    color: isSaved ? Colors.white : colors.ink,
                  ),
                ),
              ),
              CartBadgeButton(
                count: cart.count,
                onPressed: () => _openCart(context),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: colors.softSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.hairlineBorder),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 172,
                          child: Hero(
                            tag: 'book-cover-${book.id}',
                            child: BookCover(book: book, borderRadius: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - t)),
                          child: child,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.18,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.author,
                            style: TextStyle(
                              color: colors.mutedText,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              StatusBadge(status: book.status),
                              if (!book.isAvailable && book.borrowedBy != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.softSurface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: colors.hairlineBorder,
                                    ),
                                  ),
                                  child: Text(
                                    'Borrowed by ${book.borrowedBy}',
                                    style: TextStyle(
                                      color: colors.mutedText,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _ReadingTrackerCard(
                            book: book,
                            status: readingStatus,
                            entry: entry,
                            onSelectStatus: (next) {
                              final target = next == readingStatus
                                  ? ReadingStatus.none
                                  : next;
                              library.setReadingStatus(book, target);
                            },
                            onUpdateProgress: () =>
                                showReadingProgressSheet(context, book),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Description',
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.description ??
                                'No description is available for this book.',
                            style: TextStyle(
                              color: colors.mutedText,
                              fontSize: 15,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Specifications',
                            style: TextStyle(
                              color: colors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final tileWidth = (constraints.maxWidth - 10) / 2;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _SpecTile(
                                    label: 'YEAR',
                                    value: '${book.year}',
                                    width: tileWidth,
                                  ),
                                  _SpecTile(
                                    label: 'PAGES',
                                    value: book.pageCount != null
                                        ? '${book.pageCount}'
                                        : '—',
                                    width: tileWidth,
                                  ),
                                  _SpecTile(
                                    label: 'LANGUAGE',
                                    value: book.language ?? '—',
                                    width: tileWidth,
                                  ),
                                  _SpecTile(
                                    label: 'CATEGORY',
                                    value: formatCategoryLabel(book.category),
                                    width: tileWidth,
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.cardSurface,
              border: Border(top: BorderSide(color: colors.hairlineBorder)),
            ),
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _buildActionButton(
                      context: context,
                      book: book,
                      isInCart: isInCart,
                      cart: cart,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required Book book,
    required bool isInCart,
    required CartController cart,
  }) {
    if (!book.isAvailable) {
      return const IOSPrimaryButton(
        key: ValueKey('borrowed'),
        label: 'Currently borrowed',
        icon: Icons.lock_outline_rounded,
        onPressed: null,
      );
    }

    if (isInCart) {
      return IOSSecondaryButton(
        key: const ValueKey('in_basket'),
        label: 'In basket',
        icon: Icons.check_circle_rounded,
        iconColor: context.bookNestColors.available,
        onPressed: () => _openCart(context),
      );
    }

    return IOSPrimaryButton(
      key: const ValueKey('add_to_basket'),
      label: 'Add to basket',
      icon: Icons.add_shopping_cart_rounded,
      onPressed: () {
        final outcome = cart.add(book);
        if (outcome == CartAddResult.added) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              duration: const Duration(milliseconds: 1800),
              content: const Text('Added to basket'),
              action: SnackBarAction(
                label: 'View basket',
                onPressed: () => _openCart(context),
              ),
            ),
          );
        }
      },
    );
  }
}

class _ReadingTrackerCard extends StatelessWidget {
  const _ReadingTrackerCard({
    required this.book,
    required this.status,
    required this.entry,
    required this.onSelectStatus,
    required this.onUpdateProgress,
  });

  final Book book;
  final ReadingStatus status;
  final ReadingEntry? entry;
  final ValueChanged<ReadingStatus> onSelectStatus;
  final VoidCallback onUpdateProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final total = book.pageCount;
    final current = entry?.currentPage ?? 0;
    final ratio = total != null && total > 0
        ? (current / total).clamp(0.0, 1.0)
        : 0.35;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reading Tracker',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (status == ReadingStatus.reading)
                IOSPressable(
                  onTap: onUpdateProgress,
                  pressedScale: 0.94,
                  semanticLabel: 'Update page progress',
                  child: Text(
                    total != null
                        ? '$current / $total pages • Edit'
                        : 'Page $current • Edit',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ReadingPill(
                  label: 'Reading',
                  icon: Icons.menu_book_rounded,
                  selected: status == ReadingStatus.reading,
                  onTap: () => onSelectStatus(ReadingStatus.reading),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ReadingPill(
                  label: 'Finished',
                  icon: Icons.verified_rounded,
                  selected: status == ReadingStatus.finished,
                  onTap: () => onSelectStatus(ReadingStatus.finished),
                ),
              ),
            ],
          ),
          if (status == ReadingStatus.reading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: colors.cardSurface,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingPill extends StatelessWidget {
  const _ReadingPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return IOSPressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? colors.ink : colors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.ink : colors.hairlineBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : colors.ink),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : colors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.hairlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
