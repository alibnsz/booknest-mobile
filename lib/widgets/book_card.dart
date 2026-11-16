import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/app_theme.dart';
import 'book_cover.dart';
import 'ios_pressable.dart';
import 'status_badge.dart';

/// Editorial catalog grid card with native iOS tactile press and quick save toggle.
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.isSaved = false,
    this.onToggleSaved,
  });

  final Book book;
  final VoidCallback onTap;
  final bool isSaved;
  final VoidCallback? onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final colors = context.bookNestColors;
    final statusLabel = book.isAvailable ? 'Available' : 'Borrowed';

    return IOSPressable(
      onTap: onTap,
      pressedScale: 0.965,
      pressedOpacity: 0.85,
      semanticLabel: '${book.title} by ${book.author}, $statusLabel',
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.hairlineBorder),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.softSurface,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Hero(
                          tag: 'book-cover-${book.id}',
                          child: BookCover(book: book, borderRadius: 10),
                        ),
                      ),
                    ),
                    if (onToggleSaved != null)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: IOSPressable(
                          onTap: onToggleSaved,
                          pressedScale: 0.85,
                          semanticLabel: isSaved
                              ? 'Remove ${book.title} from saved'
                              : 'Save ${book.title}',
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isSaved
                                      ? colors.ink
                                      : Colors.white.withValues(alpha: 0.90),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSaved
                                        ? colors.ink
                                        : colors.hairlineBorder,
                                  ),
                                ),
                                child: Icon(
                                  isSaved
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  size: 16,
                                  color: isSaved ? Colors.white : colors.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.24,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            StatusBadge(status: book.status, compact: true),
          ],
        ),
      ),
    );
  }
}
