# BookNest Mobile — Product Requirements Document (PRD)

| Field | Value |
|---|---|
| **Project** | BookNest Mobile |
| **Type** | Mobile Application (Flutter, Android target) |
| **Version** | 1.0.1 |
| **Status** | Implemented (v1.0) |
| **Author** | Mehmet Ali Bunsuz |
| **Created** | 2026-11-14 |
| **Updated** | 2026-11-16 |
| **Repository** | `booknest-mobile` |
| **Companion Projects** | `booknest-api` (backend), `booknest-web` (web client) |
| **Context** | Mobile App Development (Android & iOS) — Flutter training, "Mini Catalog App" project |

---

## 1. Overview

BookNest Mobile lets a reader browse the BookNest catalog, search and filter books, inspect book details, and place available titles in a **borrow basket**. Confirming the basket marks the selected books as `borrowed` under the reader's name in memory.

Catalog data is loaded from `assets/data/books.json` via the `BookRepository` abstraction, keeping the app offline-ready with zero third-party runtime packages and a clean swap path to `booknest-api`.

## 2. Goals and Non-Goals

- **G1**: Deliver `Home (catalog) → Book Detail → Cart` via named routes and `Book` route arguments.
- **G2**: Present the catalog as a lazy `SliverGrid.builder` of editorial book cards with live search and category pill filtering.
- **G3**: Implement state management using only `ChangeNotifier`, `ListenableBuilder`, and `AppScope` (`InheritedWidget`).
- **G4**: Read JSON asset data into a validated `Book` model (`fromJson` / `toJson`) matching `booknest-api` and `booknest-web`.
- **G5**: Zero extra runtime packages (`cupertino_icons` removed; Flutter SDK only).
- **Non-Goals (v1.0)**: Authentication, live HTTP backend, persistence across restarts, payments, i18n, iOS build verification.

## 3. Domain Model & Business Rules

### `Book`
- Core fields: `id` (UUID v4), `title`, `author`, `category`, `year`, `status` (`available` | `borrowed`), `borrowedBy` (`String?`), `createdAt`, `updatedAt`.
- Optional mobile fields: `description`, `pageCount`, `language`, `coverAsset`.

### Business Rules
- **BR-01**: `borrowed` requires a non-empty `borrowedBy`.
- **BR-02**: `available` requires `borrowedBy == null`.
- **BR-03**: `id` and `createdAt` remain immutable after creation.
- **BR-04**: `updatedAt` refreshes in UTC on every status change.
- **BR-05**: Borrowed books cannot be added to the basket.
- **BR-06**: The basket stores each book at most once.
- **BR-07**: Checkout requires a trimmed borrower name (1–120 chars), marks all basket books as `borrowed`, clears the basket, and confirms before returning to home.

## 4. Visual Design & Motion Language

- **Editorial Minimalist Palette**: Clean off-white/charcoal surfaces (`#FAFAFA` / `#FFFFFF` in light mode, `#0E1015` / `#161922` in dark mode), hairline `#E5E7EB` borders, pill-shaped search & category chips, paired with BookNest's `indigo-600` (`#4F46E5`) primary accent and accessible `emerald-600` / `amber-600` status pills.
- **Motion & Transitions**:
  - Layered fade + vertical slide `PageRouteBuilder` transitions across named routes (`AppRoutes.onGenerateRoute`).
  - `Hero` cover transitions (`book-cover-<id>`) between grid cards and the detail showcase.
  - Tactile card press scaling (`AnimatedScale`), smooth chip/badge transitions (`AnimatedContainer` / `AnimatedSwitcher`), and detail content glide-in.
- **Refinements from Design Review**:
  - `CatalogController` owns search/category filter state; `HomeScreen` coordinates the `TextEditingController`.
  - `HomeScreen` uses `CustomScrollView` + `SliverGrid.builder` with `MediaQuery.textScalerOf`-aware `mainAxisExtent` to prevent keyboard and large-font overflows.
  - `BookDetailScreen` exposes `CartBadgeButton` in the AppBar so `Home → Book Detail → Cart` flows directly, displays all 4 specification tiles (`Year`, `Pages`, `Language`, `Category`) in a responsive `Wrap`, and listens to `Listenable.merge([catalog, cart])`.
  - `CartScreen` returns cleanly to Home after checkout confirmation via `Navigator.popUntil`.

## 5. Verification Summary

- Static analysis: `flutter analyze` (zero issues)
- Automated tests (`flutter test`): `Book` model & BR-01..BR-04, `book_filters`, `AssetBookRepository` (including real `books.json` & malformed JSON error handling), `CatalogController` & `CartController` (BR-05..BR-07), full widget/flow tests, unknown/invalid route fallback, and 360dp / 1.8x font-scale overflow tests.
