import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../routes/app_routes.dart';
import '../state/app_scope.dart';
import '../state/library_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/book_cover.dart';
import '../widgets/ios_pressable.dart';
import 'library_screen.dart';

/// Reader profile screen styled with iOS inset-grouped white cards.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onOpenLibraryFilter,
    required this.onOpenBasketTab,
    this.bottomPadding = 104,
  });

  final ValueChanged<LibraryFilter> onOpenLibraryFilter;
  final VoidCallback onOpenBasketTab;
  final double bottomPadding;

  Future<void> _editNameDialog(
    BuildContext context,
    LibraryController library,
  ) async {
    final controller = TextEditingController(text: library.readerName);
    final saved = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Edit Reader Name'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Your name',
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved != null && saved.trim().isNotEmpty) {
      library.setReaderName(saved);
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final scope = AppScope.read(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Reset Demo Library?'),
        content: const Text(
          'This restores initial book availability, saved items, and reading progress.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await scope.catalog.load();
      scope.library.resetDemoState();
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
      backgroundColor: colors.groupedCanvas,
      appBar: AppBar(
        backgroundColor: colors.groupedCanvas,
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Text(
          'Profile',
          style: TextStyle(
            color: colors.ink,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([catalog, cart, library]),
        builder: (context, _) {
          final savedCount = library.savedBooks.length;
          final readingList = library.readingBooks;
          final borrowedCount = library.borrowedBooks.length;
          final finishedCount = library.finishedBooks.length;
          final goalProgress = (finishedCount / library.yearlyGoal).clamp(
            0.0,
            1.0,
          );
          final initials = _buildInitials(library.readerName);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                key: const PageStorageKey<String>('profile_scroll'),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.hairlineBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.ink,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                library.readerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'BookNest Reader • Active Member',
                                style: TextStyle(
                                  color: colors.mutedText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IOSPressable(
                          onTap: () => _editNameDialog(context, library),
                          pressedScale: 0.90,
                          semanticLabel: 'Edit reader name',
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.softSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.hairlineBorder),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: colors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Saved',
                          value: '$savedCount',
                          onTap: () => onOpenLibraryFilter(LibraryFilter.saved),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Reading',
                          value: '${readingList.length}',
                          onTap: () =>
                              onOpenLibraryFilter(LibraryFilter.reading),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Borrowed',
                          value: '$borrowedCount',
                          onTap: () =>
                              onOpenLibraryFilter(LibraryFilter.borrowed),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Finished',
                          value: '$finishedCount',
                          onTap: () =>
                              onOpenLibraryFilter(LibraryFilter.finished),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.hairlineBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Yearly Reading Goal',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IOSPressable(
                              onTap: () =>
                                  library.setYearlyGoal(library.yearlyGoal - 1),
                              pressedScale: 0.90,
                              semanticLabel: 'Decrease reading goal',
                              child: _MiniCircleBtn(icon: Icons.remove_rounded),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$finishedCount / ${library.yearlyGoal}',
                              style: TextStyle(
                                color: colors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IOSPressable(
                              onTap: () =>
                                  library.setYearlyGoal(library.yearlyGoal + 1),
                              pressedScale: 0.90,
                              semanticLabel: 'Increase reading goal',
                              child: _MiniCircleBtn(icon: Icons.add_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: goalProgress,
                            minHeight: 8,
                            backgroundColor: colors.softSurface,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          finishedCount >= library.yearlyGoal
                              ? 'Goal reached! Keep exploring new titles.'
                              : '${library.yearlyGoal - finishedCount} more books to hit your goal.',
                          style: TextStyle(
                            color: colors.mutedText,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (readingList.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'CURRENTLY READING',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    _ActiveReadingCard(
                      book: readingList.first,
                      entry: library.entryFor(readingList.first.id),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.book,
                        arguments: readingList.first,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'COLLECTIONS & ACTIONS',
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.hairlineBorder),
                    ),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.shopping_basket_outlined,
                          title: 'Borrow Basket',
                          trailing: '${cart.count} items',
                          onTap: onOpenBasketTab,
                        ),
                        _Hairline(),
                        _SettingsRow(
                          icon: Icons.bookmark_border_rounded,
                          title: 'Saved Books',
                          trailing: '$savedCount',
                          onTap: () => onOpenLibraryFilter(LibraryFilter.saved),
                        ),
                        _Hairline(),
                        _SettingsRow(
                          icon: Icons.auto_stories_outlined,
                          title: 'Currently Reading',
                          trailing: '${readingList.length}',
                          onTap: () =>
                              onOpenLibraryFilter(LibraryFilter.reading),
                        ),
                        _Hairline(),
                        _SettingsRow(
                          icon: Icons.schedule_rounded,
                          title: 'Borrowed Books',
                          trailing: '$borrowedCount',
                          onTap: () =>
                              onOpenLibraryFilter(LibraryFilter.borrowed),
                        ),
                        _Hairline(),
                        _SettingsRow(
                          icon: Icons.refresh_rounded,
                          title: 'Reset Demo Library',
                          isDestructive: true,
                          showChevron: false,
                          onTap: () => _confirmReset(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'BN';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return IOSPressable(
      onTap: onTap,
      pressedScale: 0.94,
      semanticLabel: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.hairlineBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: colors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCircleBtn extends StatelessWidget {
  const _MiniCircleBtn({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: colors.softSurface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.hairlineBorder),
      ),
      child: Icon(icon, size: 16, color: colors.ink),
    );
  }
}

class _ActiveReadingCard extends StatelessWidget {
  const _ActiveReadingCard({
    required this.book,
    required this.entry,
    required this.onTap,
  });

  final Book book;
  final ReadingEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final total = book.pageCount;
    final current = entry?.currentPage ?? 0;
    final progress = total != null && total > 0
        ? (current / total).clamp(0.0, 1.0)
        : 0.35;

    return IOSPressable(
      onTap: onTap,
      pressedScale: 0.975,
      semanticLabel: 'Open ${book.title}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.hairlineBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: BookCover(book: book, borderRadius: 8, compact: true),
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
                    total != null ? 'Page $current of $total' : 'Page $current',
                    style: TextStyle(color: colors.mutedText, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: colors.softSurface,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: colors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final fg = isDestructive ? colors.danger : colors.ink;

    return IOSPressable(
      onTap: onTap,
      pressedScale: 0.99,
      pressedOpacity: 0.65,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: TextStyle(
                  color: colors.mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
            ],
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.mutedText,
              ),
          ],
        ),
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.8,
      thickness: 0.8,
      indent: 48,
      color: context.bookNestColors.hairlineBorder,
    );
  }
}
