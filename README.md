# BookNest Mobile

A dependency-free Flutter catalog, reading-tracker, and borrow-basket app for BookNest library members.

## Features

- **Discover Catalog**: 2-column responsive grid with live title/author search, category filters, and sorting.
- **Explore**: Recent search chips, trending horizontal shelf, and category previews.
- **My Library**: Track `Saved`, `Reading` (with page progress), `Borrowed`, and `Finished` titles.
- **Borrow Basket**: Add available books, remove items, validate borrower name (`BR-07`), and confirm checkout in memory.
- **Profile**: Editable reader profile, live reading stats, yearly reading goal, and demo state reset.
- **Native iOS Feel**: Always-light editorial palette (`ThemeMode.light`), `CupertinoPageRoute` edge-swipe transitions, `Hero` cover animations, frosted tab bar, and haptic feedback.

## Tech Stack & Architecture

- **Framework**: Flutter `3.47.7` (`stable`) · Dart `3.13.5`
- **Dependencies**: Flutter SDK only (zero external runtime packages; `cupertino_icons` removed)
- **State Management**: `ChangeNotifier` + `ListenableBuilder` + `AppScope` (`InheritedWidget`)
- **Data Layer**: Swappable `BookRepository` interface backed by [`AssetBookRepository`](lib/data/asset_book_repository.dart) reading [`assets/data/books.json`](assets/data/books.json) (lending state lives in memory and resets on restart)

## Getting Started

```bash
git clone https://github.com/alibnsz/booknest-mobile.git
cd booknest-mobile
flutter pub get
flutter run
```

> Requires an Android emulator, iOS device/simulator, or connected device with Flutter SDK installed.

### Verification

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test
```

## Companion Projects

BookNest Mobile shares its `Book` domain model and lending rules (`BR-01`–`BR-07`) with `booknest-api` and `booknest-web`. Connecting to the live REST API only requires swapping [`AssetBookRepository`](lib/data/asset_book_repository.dart) in [`lib/app.dart`](lib/app.dart).

## Author & License

**Mehmet Ali Bunsuz** · MIT License
