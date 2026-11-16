import 'package:flutter/foundation.dart';

import '../models/book.dart';
import 'catalog_controller.dart';

/// Reading progress status for a book tracked in the reader's personal library.
enum ReadingStatus { none, reading, finished }

/// Tracks a reader's current page and status for a specific book.
@immutable
class ReadingEntry {
  const ReadingEntry({
    required this.bookId,
    required this.status,
    required this.currentPage,
    required this.updatedAt,
  });

  final String bookId;
  final ReadingStatus status;
  final int currentPage;
  final DateTime updatedAt;

  ReadingEntry copyWith({
    ReadingStatus? status,
    int? currentPage,
    DateTime? updatedAt,
  }) {
    return ReadingEntry(
      bookId: bookId,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Manages reader profile, saved bookmarks, reading progress, and recent searches.
class LibraryController extends ChangeNotifier {
  LibraryController({required this._catalog}) {
    _seedDefaults();
  }

  final CatalogController _catalog;

  static const _defaultSavedIds = <String>{
    '3f1c1a7e-6c1d-4a58-9a52-2f6f2b9d7a11', // Les Misérables
    '4e8c2b10-5f74-4a29-8c31-9d1a7e3b2c44', // The Design of Everyday Things
    'c2a8e5d4-7b3f-4e1a-9d62-0f4b8a1c3e57', // Dune
  };

  static const _defaultRecentSearches = <String>[
    'Clean Code',
    'Frank Herbert',
    'Design',
    'Sci-Fi',
  ];

  String _readerName = 'Mehmet Ali';
  int _yearlyGoal = 12;
  final Set<String> _savedIds = <String>{};
  final Map<String, ReadingEntry> _readingEntries = <String, ReadingEntry>{};
  final List<String> _recentSearches = <String>[];

  String get readerName => _readerName;
  int get yearlyGoal => _yearlyGoal;
  List<String> get recentSearches => List<String>.unmodifiable(_recentSearches);

  bool isSaved(String bookId) => _savedIds.contains(bookId);

  ReadingEntry? entryFor(String bookId) => _readingEntries[bookId];

  ReadingStatus readingStatusFor(String bookId) =>
      _readingEntries[bookId]?.status ?? ReadingStatus.none;

  /// All books bookmarked by the reader and present in the loaded catalog.
  List<Book> get savedBooks {
    final result = <Book>[];
    for (final book in _catalog.books) {
      if (_savedIds.contains(book.id)) {
        result.add(book);
      }
    }
    return List<Book>.unmodifiable(result);
  }

  /// Books currently being read by the reader.
  List<Book> get readingBooks {
    final result = <Book>[];
    for (final book in _catalog.books) {
      if (_readingEntries[book.id]?.status == ReadingStatus.reading) {
        result.add(book);
      }
    }
    return List<Book>.unmodifiable(result);
  }

  /// Books marked as finished by the reader.
  List<Book> get finishedBooks {
    final result = <Book>[];
    for (final book in _catalog.books) {
      if (_readingEntries[book.id]?.status == ReadingStatus.finished) {
        result.add(book);
      }
    }
    return List<Book>.unmodifiable(result);
  }

  /// Books currently in `borrowed` status in the catalog.
  List<Book> get borrowedBooks {
    return _catalog.books
        .where((book) => !book.isAvailable)
        .toList(growable: false);
  }

  /// Toggles bookmark status for [bookId].
  void toggleSaved(String bookId) {
    if (!_savedIds.add(bookId)) {
      _savedIds.remove(bookId);
    }
    notifyListeners();
  }

  /// Updates the reading status for [book] (`none`, `reading`, or `finished`).
  void setReadingStatus(Book book, ReadingStatus status, {int? currentPage}) {
    if (status == ReadingStatus.none) {
      if (_readingEntries.remove(book.id) != null) {
        notifyListeners();
      }
      return;
    }

    final maxPages = book.pageCount;
    final resolvedPage = switch (status) {
      ReadingStatus.finished => maxPages ?? currentPage ?? 0,
      ReadingStatus.reading => _clampPage(
        currentPage ?? _readingEntries[book.id]?.currentPage ?? 1,
        maxPages,
      ),
      ReadingStatus.none => 0,
    };

    _readingEntries[book.id] = ReadingEntry(
      bookId: book.id,
      status: status,
      currentPage: resolvedPage,
      updatedAt: DateTime.now().toUtc(),
    );
    notifyListeners();
  }

  /// Updates the current page of a book being read.
  void updatePageProgress(Book book, int page) {
    final maxPages = book.pageCount;
    final clamped = _clampPage(page, maxPages);
    final isDone = maxPages != null && clamped >= maxPages;
    _readingEntries[book.id] = ReadingEntry(
      bookId: book.id,
      status: isDone ? ReadingStatus.finished : ReadingStatus.reading,
      currentPage: clamped,
      updatedAt: DateTime.now().toUtc(),
    );
    notifyListeners();
  }

  /// Adds a search phrase to the front of recent searches (max 8 entries).
  void addRecentSearch(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 8) {
      _recentSearches.removeLast();
    }
    notifyListeners();
  }

  /// Removes a single phrase from recent searches.
  void removeRecentSearch(String query) {
    if (_recentSearches.remove(query)) {
      notifyListeners();
    }
  }

  /// Clears all recent search history chips.
  void clearRecentSearches() {
    if (_recentSearches.isEmpty) return;
    _recentSearches.clear();
    notifyListeners();
  }

  /// Updates the displayed reader name.
  void setReaderName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.length > 120 || trimmed == _readerName) {
      return;
    }
    _readerName = trimmed;
    notifyListeners();
  }

  /// Updates the yearly reading goal (clamped 1..100).
  void setYearlyGoal(int goal) {
    final clamped = goal.clamp(1, 100);
    if (clamped == _yearlyGoal) return;
    _yearlyGoal = clamped;
    notifyListeners();
  }

  /// Restores initial seeded saved/reading/search demo state.
  void resetDemoState() {
    _readerName = 'Mehmet Ali';
    _yearlyGoal = 12;
    _seedDefaults();
    notifyListeners();
  }

  void _seedDefaults() {
    _savedIds
      ..clear()
      ..addAll(_defaultSavedIds);
    _recentSearches
      ..clear()
      ..addAll(_defaultRecentSearches);
    final now = DateTime.now().toUtc();
    _readingEntries
      ..clear()
      ..addAll(<String, ReadingEntry>{
        // Project Hail Mary
        '8f2c4d61-9a03-4b78-8e55-1d4f6a9c3b77': ReadingEntry(
          bookId: '8f2c4d61-9a03-4b78-8e55-1d4f6a9c3b77',
          status: ReadingStatus.reading,
          currentPage: 184,
          updatedAt: now,
        ),
        // Refactoring UI
        'a94e3c15-2b68-4f91-8d27-5c1e9b4a6d12': ReadingEntry(
          bookId: 'a94e3c15-2b68-4f91-8d27-5c1e9b4a6d12',
          status: ReadingStatus.finished,
          currentPage: 218,
          updatedAt: now,
        ),
      });
  }

  int _clampPage(int page, int? maxPages) {
    if (page < 0) return 0;
    if (maxPages != null && page > maxPages) return maxPages;
    return page;
  }
}
