import 'package:flutter/foundation.dart';

import '../data/book_repository.dart';
import '../models/book.dart';
import '../utils/book_filters.dart';

/// Lifecycle states for initial catalog loading.
enum CatalogLoadState { loading, ready, error }

/// Sort options for displaying the catalog grid.
enum CatalogSortOrder {
  featured('Featured'),
  titleAsc('Title (A–Z)'),
  authorAsc('Author (A–Z)'),
  yearDesc('Newest First');

  const CatalogSortOrder(this.label);
  final String label;
}

/// Manages the loaded book catalog, search/category filters, sorting, and lending state.
class CatalogController extends ChangeNotifier {
  CatalogController({required this._repository});

  final BookRepository _repository;

  CatalogLoadState _loadState = CatalogLoadState.loading;
  List<Book> _books = const <Book>[];
  String? _errorMessage;
  String _query = '';
  String _selectedCategory = allCategoriesKey;
  CatalogSortOrder _sortOrder = CatalogSortOrder.featured;

  CatalogLoadState get loadState => _loadState;
  List<Book> get books => List<Book>.unmodifiable(_books);
  String? get errorMessage => _errorMessage;
  String get query => _query;
  String get selectedCategory => _selectedCategory;
  CatalogSortOrder get sortOrder => _sortOrder;

  bool get hasActiveFilters =>
      _query.trim().isNotEmpty ||
      _selectedCategory != allCategoriesKey ||
      _sortOrder != CatalogSortOrder.featured;

  List<String> get categories => extractCategories(_books);

  List<Book> get filteredBooks {
    final filtered = filterBooks(
      _books,
      query: _query,
      category: _selectedCategory,
    );
    if (_sortOrder == CatalogSortOrder.featured) {
      return filtered;
    }
    final sorted = List<Book>.from(filtered);
    switch (_sortOrder) {
      case CatalogSortOrder.featured:
        break;
      case CatalogSortOrder.titleAsc:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case CatalogSortOrder.authorAsc:
        sorted.sort(
          (a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()),
        );
      case CatalogSortOrder.yearDesc:
        sorted.sort((a, b) => b.year.compareTo(a.year));
    }
    return List<Book>.unmodifiable(sorted);
  }

  /// Loads catalog entries from the repository.
  Future<void> load() async {
    _loadState = CatalogLoadState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final loaded = await _repository.findAll();
      _books = List<Book>.from(loaded);
      _loadState = CatalogLoadState.ready;
    } on BookRepositoryException catch (error) {
      _errorMessage = error.message;
      _loadState = CatalogLoadState.error;
    } on Exception {
      _errorMessage = 'Something went wrong while loading the catalog.';
      _loadState = CatalogLoadState.error;
    }
    notifyListeners();
  }

  /// Returns the latest in-memory snapshot for [id], or `null` if absent.
  Book? findById(String id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  /// Updates the live search query.
  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  /// Selects a category filter chip (`"All"` resets category filtering).
  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  /// Updates the active sort order.
  void setSortOrder(CatalogSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    notifyListeners();
  }

  /// Resets search query, selected category, and sort order.
  void clearFilters() {
    if (!hasActiveFilters) return;
    _query = '';
    _selectedCategory = allCategoriesKey;
    _sortOrder = CatalogSortOrder.featured;
    notifyListeners();
  }

  /// Marks all books matching [bookIds] as borrowed under [borrowerName] (BR-07).
  void lend(Iterable<String> bookIds, String borrowerName) {
    final trimmedName = borrowerName.trim();
    if (trimmedName.isEmpty || trimmedName.length > 120) {
      throw ArgumentError(
        'Borrower name must be between 1 and 120 characters.',
      );
    }

    final targetIds = bookIds.toSet();
    if (targetIds.isEmpty) return;

    final now = DateTime.now().toUtc();
    var changed = false;

    final updated = _books
        .map((book) {
          if (!targetIds.contains(book.id)) return book;
          changed = true;
          return book.markBorrowed(trimmedName, at: now);
        })
        .toList(growable: false);

    if (changed) {
      _books = updated;
      notifyListeners();
    }
  }
}
