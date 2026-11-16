/// Lending availability status of a [Book] in the BookNest catalog.
enum BookStatus {
  available,
  borrowed;

  /// Wire format used in JSON and the BookNest API.
  String get jsonValue => name;

  /// Parses a wire-format string into a [BookStatus].
  static BookStatus fromJsonValue(Object? raw) {
    if (raw == 'available') return BookStatus.available;
    if (raw == 'borrowed') return BookStatus.borrowed;
    throw FormatException('Invalid book status: $raw');
  }
}

/// Core domain entity shared across BookNest API, Web, and Mobile.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.year,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.borrowedBy,
    this.description,
    this.pageCount,
    this.language,
    this.coverAsset,
  });

  static const Object _unset = Object();

  final String id;
  final String title;
  final String author;
  final String category;
  final int year;
  final BookStatus status;
  final String? borrowedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional mobile extension fields.
  final String? description;
  final int? pageCount;
  final String? language;
  final String? coverAsset;

  /// Whether the book can currently be added to the borrow basket.
  bool get isAvailable => status == BookStatus.available;

  /// Parses a JSON object into a validated [Book].
  factory Book.fromJson(Map<String, dynamic> json) {
    final id = _requireString(json, 'id', maxLength: 100);
    final title = _requireString(json, 'title', maxLength: 200);
    final author = _requireString(json, 'author', maxLength: 120);
    final category = _requireString(json, 'category', maxLength: 60);
    final year = _requireInt(json, 'year');
    final currentYear = DateTime.now().year;
    if (year < 0 || year > currentYear) {
      throw FormatException('Book "$id" has invalid year: $year');
    }

    final status = BookStatus.fromJsonValue(json['status']);
    final borrowedBy = _optionalString(json, 'borrowedBy', maxLength: 120);

    // BR-01 & BR-02: borrowedBy presence must match lending status.
    if (status == BookStatus.borrowed &&
        (borrowedBy == null || borrowedBy.isEmpty)) {
      throw FormatException('Borrowed book "$id" is missing borrowedBy');
    }
    if (status == BookStatus.available && borrowedBy != null) {
      throw FormatException('Available book "$id" must have null borrowedBy');
    }

    final createdAt = _requireDateTime(json, 'createdAt');
    final updatedAt = _requireDateTime(json, 'updatedAt');

    final description = _optionalString(json, 'description');
    final pageCountRaw = json['pageCount'];
    int? pageCount;
    if (pageCountRaw != null) {
      if (pageCountRaw is! int || pageCountRaw <= 0) {
        throw FormatException(
          'Book "$id" has invalid pageCount: $pageCountRaw',
        );
      }
      pageCount = pageCountRaw;
    }

    final language = _optionalString(json, 'language');
    final coverAsset = _optionalString(json, 'coverAsset');

    return Book(
      id: id,
      title: title,
      author: author,
      category: category,
      year: year,
      status: status,
      borrowedBy: borrowedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      description: description,
      pageCount: pageCount,
      language: language,
      coverAsset: coverAsset,
    );
  }

  /// Serializes this [Book] into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'year': year,
      'status': status.jsonValue,
      'borrowedBy': borrowedBy,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'description': description,
      'pageCount': pageCount,
      'language': language,
      'coverAsset': coverAsset,
    };
  }

  /// Returns a copy with updated fields; nullable fields support explicit `null`.
  Book copyWith({
    String? title,
    String? author,
    String? category,
    int? year,
    BookStatus? status,
    Object? borrowedBy = _unset,
    DateTime? updatedAt,
    Object? description = _unset,
    Object? pageCount = _unset,
    Object? language = _unset,
    Object? coverAsset = _unset,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      year: year ?? this.year,
      status: status ?? this.status,
      borrowedBy: identical(borrowedBy, _unset)
          ? this.borrowedBy
          : borrowedBy as String?,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      pageCount: identical(pageCount, _unset)
          ? this.pageCount
          : pageCount as int?,
      language: identical(language, _unset)
          ? this.language
          : language as String?,
      coverAsset: identical(coverAsset, _unset)
          ? this.coverAsset
          : coverAsset as String?,
    );
  }

  /// Transitions an available book to `borrowed` while enforcing BR-01, BR-04, BR-07.
  Book markBorrowed(String borrowerName, {DateTime? at}) {
    if (!isAvailable) {
      throw StateError('Book "$title" is already borrowed');
    }
    final trimmed = borrowerName.trim();
    if (trimmed.isEmpty || trimmed.length > 120) {
      throw ArgumentError('Borrower name must be between 1 and 120 characters');
    }
    return copyWith(
      status: BookStatus.borrowed,
      borrowedBy: trimmed,
      updatedAt: (at ?? DateTime.now()).toUtc(),
    );
  }

  /// Transitions a borrowed book back to `available` while enforcing BR-02, BR-04.
  Book markReturned({DateTime? at}) {
    return copyWith(
      status: BookStatus.available,
      borrowedBy: null,
      updatedAt: (at ?? DateTime.now()).toUtc(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Book &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            author == other.author &&
            category == other.category &&
            year == other.year &&
            status == other.status &&
            borrowedBy == other.borrowedBy &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt &&
            description == other.description &&
            pageCount == other.pageCount &&
            language == other.language &&
            coverAsset == other.coverAsset;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    author,
    category,
    year,
    status,
    borrowedBy,
    createdAt,
    updatedAt,
    description,
    pageCount,
    language,
    coverAsset,
  );

  static String _requireString(
    Map<String, dynamic> json,
    String key, {
    int? maxLength,
  }) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Missing or invalid string field "$key"');
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty || (maxLength != null && trimmed.length > maxLength)) {
      throw FormatException('Field "$key" length is out of bounds');
    }
    return trimmed;
  }

  static String? _optionalString(
    Map<String, dynamic> json,
    String key, {
    int? maxLength,
  }) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Invalid string field "$key"');
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (maxLength != null && trimmed.length > maxLength) {
      throw FormatException('Field "$key" exceeds $maxLength characters');
    }
    return trimmed;
  }

  static int _requireInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Missing or invalid integer field "$key"');
    }
    return value;
  }

  static DateTime _requireDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Missing or invalid timestamp field "$key"');
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid ISO-8601 timestamp for "$key": $value');
    }
    return parsed;
  }
}
