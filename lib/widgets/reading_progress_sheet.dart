import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/book.dart';
import '../state/app_scope.dart';
import '../state/library_controller.dart';
import '../theme/app_theme.dart';
import 'ios_pressable.dart';

/// Opens a native iOS-style modal sheet for updating reading page progress.
Future<void> showReadingProgressSheet(BuildContext context, Book book) async {
  final library = AppScope.read(context).library;
  final current = library.entryFor(book.id)?.currentPage ?? 1;
  final maxPages = book.pageCount ?? 500;
  var draftPage = current.clamp(0, maxPages);

  await showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) {
      final colors = sheetContext.bookNestColors;
      return StatefulBuilder(
        builder: (context, setModalState) {
          final pct = maxPages > 0 ? ((draftPage / maxPages) * 100).round() : 0;

          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.cardSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20 + MediaQuery.paddingOf(sheetContext).bottom,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: colors.hairlineBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Update Progress',
                      style: TextStyle(
                        color: colors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Page $draftPage of $maxPages',
                          style: TextStyle(
                            color: colors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.softSurface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$pct%',
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoSlider(
                        value: draftPage.toDouble(),
                        min: 0,
                        max: maxPages.toDouble(),
                        activeColor: colors.accent,
                        onChanged: (value) {
                          final rounded = value.round();
                          if (rounded != draftPage) {
                            setModalState(() => draftPage = rounded);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: IOSSecondaryButton(
                            label: '-10 pages',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setModalState(
                                () => draftPage = (draftPage - 10).clamp(
                                  0,
                                  maxPages,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: IOSSecondaryButton(
                            label: '+10 pages',
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setModalState(
                                () => draftPage = (draftPage + 10).clamp(
                                  0,
                                  maxPages,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    IOSPrimaryButton(
                      label: draftPage >= maxPages
                          ? 'Mark as finished'
                          : 'Save progress',
                      onPressed: () {
                        library.updatePageProgress(book, draftPage);
                        Navigator.pop(sheetContext);
                      },
                    ),
                    const SizedBox(height: 8),
                    IOSSecondaryButton(
                      label: 'Mark finished now',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: colors.available,
                      onPressed: () {
                        library.setReadingStatus(book, ReadingStatus.finished);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
