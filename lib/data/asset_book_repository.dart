import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/book.dart';
import 'book_repository.dart';

/// Reads the book catalog from a bundled JSON asset.
class AssetBookRepository implements BookRepository {
  AssetBookRepository({
    AssetBundle? bundle,
    this.assetPath = 'assets/data/books.json',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;

  @override
  Future<List<Book>> findAll() async {
    final String rawJson;
    try {
      rawJson = await _bundle.loadString(assetPath);
    } on Exception catch (error) {
      throw BookRepositoryException(
        'Could not read the catalog data file.',
        error,
      );
    }

    if (rawJson.trim().isEmpty) {
      throw const BookRepositoryException('Catalog data file is empty.');
    }

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List<dynamic>) {
        throw const FormatException('Expected a JSON array of books.');
      }

      final books = <Book>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Each book entry must be a JSON object.');
        }
        books.add(Book.fromJson(item));
      }
      return books;
    } on FormatException catch (error) {
      throw BookRepositoryException(
        'Catalog data is malformed and could not be loaded.',
        error,
      );
    }
  }

  @override
  Future<Book?> findById(String id) async {
    final books = await findAll();
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }
}
