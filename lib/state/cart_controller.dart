import 'package:flutter/foundation.dart';

import '../models/book.dart';
import 'catalog_controller.dart';

/// Outcome returned when attempting to add a book to the borrow basket.
enum CartAddResult { added, alreadyBorrowed, alreadyInCart }

/// Outcome returned when attempting to confirm the borrow basket.
class CheckoutResult {
  const CheckoutResult._({
    required this.isSuccess,
    this.borrowedCount = 0,
    this.borrowerName,
    this.errorMessage,
  });

  factory CheckoutResult.success({
    required int borrowedCount,
    required String borrowerName,
  }) => CheckoutResult._(
    isSuccess: true,
    borrowedCount: borrowedCount,
    borrowerName: borrowerName,
  );

  factory CheckoutResult.failure(String message) =>
      CheckoutResult._(isSuccess: false, errorMessage: message);

  final bool isSuccess;
  final int borrowedCount;
  final String? borrowerName;
  final String? errorMessage;
}

/// Manages the reader's borrow basket and enforces lending rules BR-05 to BR-07.
class CartController extends ChangeNotifier {
  CartController({required this._catalog});

  final CatalogController _catalog;
  final List<String> _bookIds = <String>[];

  /// Books currently in the basket, resolved against the live catalog state.
  List<Book> get items {
    final resolved = <Book>[];
    for (final id in _bookIds) {
      final book = _catalog.findById(id);
      if (book != null) {
        resolved.add(book);
      }
    }
    return List<Book>.unmodifiable(resolved);
  }

  int get count => items.length;
  bool get isEmpty => items.isEmpty;

  bool contains(String bookId) => _bookIds.contains(bookId);

  /// Adds [book] to the basket if available (BR-05) and not already present (BR-06).
  CartAddResult add(Book book) {
    final liveBook = _catalog.findById(book.id) ?? book;
    if (!liveBook.isAvailable) {
      return CartAddResult.alreadyBorrowed;
    }
    if (_bookIds.contains(liveBook.id)) {
      return CartAddResult.alreadyInCart;
    }
    _bookIds.add(liveBook.id);
    notifyListeners();
    return CartAddResult.added;
  }

  /// Removes the book with [bookId] from the basket.
  void remove(String bookId) {
    if (_bookIds.remove(bookId)) {
      notifyListeners();
    }
  }

  /// Validates the borrower name against BR-07 (trimmed, 1–120 characters).
  String? validateBorrowerName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) {
      return 'Please enter your name';
    }
    if (trimmed.length > 120) {
      return 'Name must be 120 characters or less';
    }
    return null;
  }

  /// Confirms borrowing for all basket items under [rawBorrowerName] (BR-07).
  CheckoutResult checkout(String rawBorrowerName) {
    final currentItems = items;
    if (currentItems.isEmpty) {
      return CheckoutResult.failure('Your basket is empty.');
    }

    final validationError = validateBorrowerName(rawBorrowerName);
    if (validationError != null) {
      return CheckoutResult.failure(validationError);
    }

    for (final book in currentItems) {
      if (!book.isAvailable) {
        return CheckoutResult.failure(
          '"${book.title}" is no longer available.',
        );
      }
    }

    final trimmedName = rawBorrowerName.trim();
    final idsToLend = currentItems.map((b) => b.id).toList(growable: false);
    _catalog.lend(idsToLend, trimmedName);
    _bookIds.clear();
    notifyListeners();

    return CheckoutResult.success(
      borrowedCount: idsToLend.length,
      borrowerName: trimmedName,
    );
  }
}
