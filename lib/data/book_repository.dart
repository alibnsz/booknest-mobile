import '../models/book.dart';

/// Contract implemented by every catalog data source (bundled asset now, HTTP later).
abstract class BookRepository {
  Future<List<Book>> findAll();
  Future<Book?> findById(String id);
}

/// Domain-friendly exception surfaced when loading catalog data fails.
class BookRepositoryException implements Exception {
  const BookRepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
