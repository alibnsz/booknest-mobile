import 'package:flutter_test/flutter_test.dart';

import 'package:booknest_mobile/models/book.dart';
import 'package:booknest_mobile/utils/book_filters.dart';

void main() {
  group('Book model', () {
    final baseJson = <String, dynamic>{
      'id': '3f1c1a7e-6c1d-4a58-9a52-2f6f2b9d7a11',
      'title': 'Les Misérables',
      'author': 'Victor Hugo',
      'category': 'novel',
      'year': 1862,
      'status': 'available',
      'borrowedBy': null,
      'createdAt': '2026-11-14T10:00:00.000Z',
      'updatedAt': '2026-11-14T10:00:00.000Z',
      'description': 'A classic French novel.',
      'pageCount': 1463,
      'language': 'French',
      'coverAsset': 'assets/images/covers/les-miserables.png',
    };

    test('fromJson and toJson perform a lossless round trip', () {
      final book = Book.fromJson(baseJson);
      expect(book.id, baseJson['id']);
      expect(book.title, 'Les Misérables');
      expect(book.status, BookStatus.available);
      expect(book.isAvailable, isTrue);
      expect(book.borrowedBy, isNull);
      expect(book.pageCount, 1463);

      final reencoded = Book.fromJson(book.toJson());
      expect(reencoded, book);
    });

    test('enforces BR-01: borrowed book requires non-empty borrowedBy', () {
      final invalid = Map<String, dynamic>.from(baseJson)
        ..['status'] = 'borrowed'
        ..['borrowedBy'] = null;
      expect(() => Book.fromJson(invalid), throwsFormatException);
    });

    test('enforces BR-02: available book must have null borrowedBy', () {
      final invalid = Map<String, dynamic>.from(baseJson)
        ..['status'] = 'available'
        ..['borrowedBy'] = 'Someone';
      expect(() => Book.fromJson(invalid), throwsFormatException);
    });

    test('markBorrowed and markReturned enforce BR-01 through BR-04', () {
      final original = Book.fromJson(baseJson);
      final borrowTime = DateTime.utc(2026, 11, 16, 12, 0, 0);
      final borrowed = original.markBorrowed('  Ayşe Yılmaz  ', at: borrowTime);

      expect(borrowed.id, original.id);
      expect(borrowed.createdAt, original.createdAt);
      expect(borrowed.status, BookStatus.borrowed);
      expect(borrowed.borrowedBy, 'Ayşe Yılmaz');
      expect(borrowed.updatedAt, borrowTime);

      final returnTime = DateTime.utc(2026, 11, 17, 9, 0, 0);
      final returned = borrowed.markReturned(at: returnTime);
      expect(returned.status, BookStatus.available);
      expect(returned.borrowedBy, isNull);
      expect(returned.updatedAt, returnTime);
    });
  });

  group('book_filters', () {
    final now = DateTime.utc(2026, 11, 14);
    final books = [
      Book(
        id: '1',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        category: 'software',
        year: 2008,
        status: BookStatus.available,
        createdAt: now,
        updatedAt: now,
      ),
      Book(
        id: '2',
        title: 'Dune',
        author: 'Frank Herbert',
        category: 'sci-fi',
        year: 1965,
        status: BookStatus.borrowed,
        borrowedBy: 'Ali',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    test('filters case-insensitively by title or author and category', () {
      expect(filterBooks(books, query: '  herbert '), [books[1]]);
      expect(filterBooks(books, query: 'clean'), [books[0]]);
      expect(filterBooks(books, category: 'sci-fi'), [books[1]]);
      expect(filterBooks(books, category: allCategoriesKey), books);
      expect(filterBooks(books, query: 'dune', category: 'software'), isEmpty);
    });

    test('extractCategories and formatCategoryLabel format cleanly', () {
      expect(extractCategories(books), ['All', 'sci-fi', 'software']);
      expect(formatCategoryLabel('sci-fi'), 'Sci-Fi');
      expect(formatCategoryLabel('novel'), 'Novel');
    });
  });
}
