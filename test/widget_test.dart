import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:booknest_mobile/app.dart';
import 'package:booknest_mobile/data/book_repository.dart';
import 'package:booknest_mobile/models/book.dart';
import 'package:booknest_mobile/routes/app_routes.dart';
import 'package:booknest_mobile/widgets/book_card.dart';
import 'package:booknest_mobile/widgets/status_badge.dart';

class _InMemoryBookRepository implements BookRepository {
  _InMemoryBookRepository(this.books);

  final List<Book> books;

  @override
  Future<List<Book>> findAll() async => books;

  @override
  Future<Book?> findById(String id) async {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }
}

void main() {
  final now = DateTime.utc(2026, 11, 14);
  final demoBooks = [
    Book(
      id: 'id-dune',
      title: 'Dune',
      author: 'Frank Herbert',
      category: 'sci-fi',
      year: 1965,
      status: BookStatus.available,
      createdAt: now,
      updatedAt: now,
      description: 'A desert planet and a prophecy.',
      pageCount: 612,
      language: 'English',
    ),
    Book(
      id: 'id-clean',
      title: 'Clean Code',
      author: 'Robert C. Martin',
      category: 'software',
      year: 2008,
      status: BookStatus.borrowed,
      borrowedBy: 'Ahmet Yılmaz',
      createdAt: now,
      updatedAt: now,
      description: 'Agile software craftsmanship.',
      pageCount: 464,
      language: 'English',
    ),
  ];

  testWidgets('BookCard and StatusBadge display book info and status text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: SizedBox(
            width: 170,
            height: 270,
            child: BookCard(book: demoBooks[0], onTap: () {}),
          ),
        ),
      ),
    );

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Frank Herbert'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge(status: BookStatus.borrowed)),
      ),
    );
    expect(find.text('Borrowed'), findsOneWidget);
  });

  testWidgets(
    'Full flow: browse, filter, open detail, add, validate cart, and checkout',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BookNestApp(repository: _InMemoryBookRepository(demoBooks)),
      );
      await tester.pumpAndSettle();

      // Home displays both books and always stays in light theme.
      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Clean Code'), findsOneWidget);
      final scaffoldContext = tester.element(find.text('Discover'));
      expect(Theme.of(scaffoldContext).brightness, Brightness.light);

      // Search filters live and shows empty state when no match.
      await tester.enterText(find.byType(TextField), 'Nonexistent');
      await tester.pumpAndSettle();
      expect(find.text('No books match your search'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Dune'), findsOneWidget);

      // Borrowed book cannot be added.
      await tester.tap(find.text('Clean Code'));
      await tester.pumpAndSettle();
      expect(find.text('Currently borrowed'), findsOneWidget);
      expect(find.text('Borrowed by Ahmet Yılmaz'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Available book can be opened and added to basket.
      await tester.tap(find.text('Dune'));
      await tester.pumpAndSettle();
      expect(find.text('Add to basket'), findsOneWidget);

      await tester.tap(find.text('Add to basket'));
      await tester.pumpAndSettle();
      expect(find.text('In basket'), findsOneWidget);

      // Open cart from AppBar badge button.
      await tester.tap(find.byIcon(Icons.shopping_basket_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Borrow basket'), findsOneWidget);

      // Empty borrower name shows inline error (BR-07).
      await tester.tap(find.text('Confirm borrowing'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your name'), findsOneWidget);

      // Valid checkout updates book to borrowed and returns to home.
      await tester.enterText(find.byType(TextField), 'Ali');
      await tester.tap(find.text('Confirm borrowing'));
      await tester.pumpAndSettle();
      expect(find.text('Borrowing confirmed'), findsOneWidget);

      await tester.tap(find.text('Back to catalog'));
      await tester.pumpAndSettle();

      // Both books are now Borrowed on the home grid.
      expect(find.text('Borrowed'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Bottom navigation switches across Explore, Library, Basket, and Profile',
    (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        BookNestApp(repository: _InMemoryBookRepository(demoBooks)),
      );
      await tester.pumpAndSettle();

      // Explore tab.
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(find.text('Recent Search'), findsOneWidget);
      expect(find.text('Trending '), findsNothing);

      // Library tab.
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.text('My Library'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);

      // Basket tab.
      await tester.tap(find.text('Basket'));
      await tester.pumpAndSettle();
      expect(find.text('Your basket is empty'), findsOneWidget);

      // Profile tab.
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Mehmet Ali'), findsOneWidget);
      expect(find.text('Yearly Reading Goal'), findsOneWidget);
    },
  );

  testWidgets('Cart screen shows empty state when no items remain', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      BookNestApp(repository: _InMemoryBookRepository(demoBooks)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dune'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to basket'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.shopping_basket_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.remove_circle_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Your basket is empty'), findsOneWidget);
  });

  testWidgets('Unknown route shows NotFoundScreen cleanly', (tester) async {
    await tester.pumpWidget(
      BookNestApp(repository: _InMemoryBookRepository(demoBooks)),
    );
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed('/unknown-route');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
    await tester.tap(find.text('Back to catalog'));
    await tester.pumpAndSettle();
    expect(find.text('Discover'), findsOneWidget);
  });

  testWidgets('360dp viewport with 1.8x text scale renders without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: BookNestApp(repository: _InMemoryBookRepository(demoBooks)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dune'), findsOneWidget);

    await tester.ensureVisible(find.text('Dune'));
    await tester.tap(find.text('Dune'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Specifications'), findsOneWidget);
  });

  testWidgets('Opening /book without arguments renders NotFoundScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      BookNestApp(repository: _InMemoryBookRepository(demoBooks)),
    );
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed(AppRoutes.book);
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
  });
}
