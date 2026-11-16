import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:booknest_mobile/data/asset_book_repository.dart';
import 'package:booknest_mobile/data/book_repository.dart';
import 'package:booknest_mobile/models/book.dart';
import 'package:booknest_mobile/state/cart_controller.dart';
import 'package:booknest_mobile/state/catalog_controller.dart';
import 'package:booknest_mobile/state/library_controller.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._payload, {this.shouldThrow = false});

  final String _payload;
  final bool shouldThrow;

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError();
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (shouldThrow) {
      throw Exception('Asset missing');
    }
    return _payload;
  }
}

class _FakeBookRepository implements BookRepository {
  _FakeBookRepository(this._books, {this.shouldFail = false});

  final List<Book> _books;
  final bool shouldFail;

  @override
  Future<List<Book>> findAll() async {
    if (shouldFail) {
      throw const BookRepositoryException('Simulated load error');
    }
    return _books;
  }

  @override
  Future<Book?> findById(String id) async {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 11, 14);
  final sampleBooks = [
    Book(
      id: 'b-1',
      title: 'Dune',
      author: 'Frank Herbert',
      category: 'sci-fi',
      year: 1965,
      status: BookStatus.available,
      createdAt: now,
      updatedAt: now,
    ),
    Book(
      id: 'b-2',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'software',
      year: 2008,
      status: BookStatus.borrowed,
      borrowedBy: 'Ahmet',
      createdAt: now,
      updatedAt: now,
    ),
  ];

  group('AssetBookRepository', () {
    test('loads real bundled assets/data/books.json cleanly', () async {
      final repo = AssetBookRepository();
      final books = await repo.findAll();
      expect(books.length, inInclusiveRange(12, 16));
      expect(
        books.where((b) => !b.isAvailable).length,
        greaterThanOrEqualTo(2),
      );
      expect(
        books.map((b) => b.category).toSet().length,
        greaterThanOrEqualTo(4),
      );
    });

    test('throws BookRepositoryException on empty or malformed JSON', () async {
      final emptyRepo = AssetBookRepository(bundle: _FakeAssetBundle('   '));
      await expectLater(
        emptyRepo.findAll(),
        throwsA(isA<BookRepositoryException>()),
      );

      final badJsonRepo = AssetBookRepository(
        bundle: _FakeAssetBundle('{not-a-list}'),
      );
      await expectLater(
        badJsonRepo.findAll(),
        throwsA(isA<BookRepositoryException>()),
      );

      final missingRepo = AssetBookRepository(
        bundle: _FakeAssetBundle('', shouldThrow: true),
      );
      await expectLater(
        missingRepo.findAll(),
        throwsA(isA<BookRepositoryException>()),
      );
    });
  });

  group('CatalogController & CartController', () {
    test(
      'enforces BR-05, BR-06, and BR-07 during basket and checkout',
      () async {
        final catalog = CatalogController(
          repository: _FakeBookRepository(sampleBooks),
        );
        await catalog.load();
        final cart = CartController(catalog: catalog);

        expect(catalog.loadState, CatalogLoadState.ready);
        expect(cart.add(sampleBooks[1]), CartAddResult.alreadyBorrowed);
        expect(cart.add(sampleBooks[0]), CartAddResult.added);
        expect(cart.add(sampleBooks[0]), CartAddResult.alreadyInCart);
        expect(cart.count, 1);

        final emptyNameResult = cart.checkout('   ');
        expect(emptyNameResult.isSuccess, isFalse);
        expect(emptyNameResult.errorMessage, isNotNull);

        final longNameResult = cart.checkout('A' * 121);
        expect(longNameResult.isSuccess, isFalse);

        final okResult = cart.checkout('  Mehmet Ali  ');
        expect(okResult.isSuccess, isTrue);
        expect(okResult.borrowedCount, 1);
        expect(okResult.borrowerName, 'Mehmet Ali');
        expect(cart.isEmpty, isTrue);

        final updatedBook = catalog.findById('b-1')!;
        expect(updatedBook.status, BookStatus.borrowed);
        expect(updatedBook.borrowedBy, 'Mehmet Ali');
        expect(updatedBook.updatedAt.isAfter(now), isTrue);
      },
    );

    test('surfaces repository error state when loading fails', () async {
      final catalog = CatalogController(
        repository: _FakeBookRepository(sampleBooks, shouldFail: true),
      );
      await catalog.load();
      expect(catalog.loadState, CatalogLoadState.error);
      expect(catalog.errorMessage, 'Simulated load error');
    });

    test(
      'LibraryController tracks saved, reading progress, searches, and profile',
      () async {
        final booksWithPages = [
          sampleBooks[0].copyWith(pageCount: 400),
          sampleBooks[1].copyWith(pageCount: 300),
        ];
        final catalog = CatalogController(
          repository: _FakeBookRepository(booksWithPages),
        );
        await catalog.load();
        final library = LibraryController(catalog: catalog);

        expect(library.isSaved('b-1'), isFalse);
        library.toggleSaved('b-1');
        expect(library.isSaved('b-1'), isTrue);
        expect(library.savedBooks.map((b) => b.id), ['b-1']);

        library.setReadingStatus(
          booksWithPages[0],
          ReadingStatus.reading,
          currentPage: 120,
        );
        expect(library.readingBooks.map((b) => b.id), ['b-1']);
        expect(library.entryFor('b-1')?.currentPage, 120);

        library.updatePageProgress(booksWithPages[0], 400);
        expect(library.readingStatusFor('b-1'), ReadingStatus.finished);
        expect(library.finishedBooks.map((b) => b.id), ['b-1']);

        library.addRecentSearch('Herbert');
        expect(library.recentSearches.first, 'Herbert');
        library.removeRecentSearch('Herbert');
        expect(library.recentSearches.contains('Herbert'), isFalse);

        library.setReaderName('  Ali  ');
        library.setYearlyGoal(20);
        expect(library.readerName, 'Ali');
        expect(library.yearlyGoal, 20);

        library.resetDemoState();
        expect(library.readerName, 'Mehmet Ali');
        expect(library.yearlyGoal, 12);
      },
    );
  });
}
