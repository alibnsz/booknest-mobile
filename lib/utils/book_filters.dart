import '../models/book.dart';

/// Sentinel label representing all categories in the catalog filter bar.
const String allCategoriesKey = 'All';

/// Filters [books] by case-insensitive title/author [query] and [category].
List<Book> filterBooks(
  List<Book> books, {
  String query = '',
  String? category,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final normalizedCategory = category?.trim().toLowerCase();
  final filterByCategory =
      normalizedCategory != null &&
      normalizedCategory.isNotEmpty &&
      normalizedCategory != allCategoriesKey.toLowerCase();

  return books
      .where((book) {
        if (filterByCategory &&
            book.category.toLowerCase() != normalizedCategory) {
          return false;
        }
        if (normalizedQuery.isEmpty) {
          return true;
        }
        return book.title.toLowerCase().contains(normalizedQuery) ||
            book.author.toLowerCase().contains(normalizedQuery);
      })
      .toList(growable: false);
}

/// Extracts sorted unique category keys from [books], prefixed with "All".
List<String> extractCategories(List<Book> books) {
  final seen = <String>{};
  final categories = <String>[];
  for (final book in books) {
    final key = book.category.trim().toLowerCase();
    if (key.isNotEmpty && seen.add(key)) {
      categories.add(key);
    }
  }
  categories.sort();
  return <String>[allCategoriesKey, ...categories];
}

/// Formats a raw category slug (e.g. "sci-fi") for clean UI display ("Sci-Fi").
String formatCategoryLabel(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;
  if (trimmed.toLowerCase() == 'all') return allCategoriesKey;
  return trimmed
      .split('-')
      .map(
        (segment) => segment.isEmpty
            ? segment
            : '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
      )
      .join('-');
}
