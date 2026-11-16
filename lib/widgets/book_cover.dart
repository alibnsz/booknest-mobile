import 'package:flutter/material.dart';

import '../models/book.dart';
import '../utils/book_filters.dart';

/// Displays a book's PNG cover asset or falls back to a generated editorial cover.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.borderRadius = 12,
    this.compact = false,
  });

  final Book book;
  final double borderRadius;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final asset = book.coverAsset;
    final radius = BorderRadius.circular(borderRadius);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: compact ? 8 : 16,
              offset: Offset(0, compact ? 3 : 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: AspectRatio(
            aspectRatio: 480 / 680,
            child: asset != null && asset.isNotEmpty
                ? Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    semanticLabel: '${book.title} cover',
                    errorBuilder: (_, _, _) =>
                        _GeneratedBookCover(book: book, compact: compact),
                  )
                : _GeneratedBookCover(book: book, compact: compact),
          ),
        ),
      ),
    );
  }
}

class _GeneratedBookCover extends StatelessWidget {
  const _GeneratedBookCover({required this.book, required this.compact});

  final Book book;
  final bool compact;

  static const _palettes = <({Color bg, Color accent, Color fg})>[
    (bg: Color(0xFF1E1B4B), accent: Color(0xFF818CF8), fg: Color(0xFFF8FAFC)),
    (bg: Color(0xFFFDF8F0), accent: Color(0xFFD97706), fg: Color(0xFF1C1917)),
    (bg: Color(0xFFECFDF5), accent: Color(0xFF059669), fg: Color(0xFF064E3B)),
    (bg: Color(0xFFF1F5F9), accent: Color(0xFF4F46E5), fg: Color(0xFF0F172A)),
    (bg: Color(0xFF27272A), accent: Color(0xFFF43F5E), fg: Color(0xFFFAFAFA)),
  ];

  @override
  Widget build(BuildContext context) {
    final paletteIndex =
        book.id.codeUnits.fold<int>(0, (sum, c) => sum + c) % _palettes.length;
    final palette = _palettes[paletteIndex];
    final initial = book.title.trim().isNotEmpty
        ? book.title.trim()[0].toUpperCase()
        : 'B';

    return Semantics(
      label: '${book.title} cover',
      child: ExcludeSemantics(
        child: MediaQuery.withNoTextScaling(
          child: Container(
            color: palette.bg,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Subtle left spine crease.
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: compact ? 3 : 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                // Decorative geometric motif.
                Positioned(
                  right: compact ? -14 : -24,
                  bottom: compact ? -14 : -24,
                  child: Container(
                    width: compact ? 44 : 92,
                    height: compact ? 44 : 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.accent.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                if (compact)
                  Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: palette.fg,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.fg.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            formatCategoryLabel(book.category).toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.fg.withValues(alpha: 0.85),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: palette.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: palette.accent.withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: palette.fg,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Georgia',
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Minimalist decorative editorial lines.
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: palette.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 72,
                          height: 3,
                          decoration: BoxDecoration(
                            color: palette.fg.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
