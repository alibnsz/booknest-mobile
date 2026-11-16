import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Semantic and surface color tokens extending Material 3 [ThemeData].
@immutable
class BookNestColors extends ThemeExtension<BookNestColors> {
  const BookNestColors({
    required this.canvas,
    required this.groupedCanvas,
    required this.cardSurface,
    required this.softSurface,
    required this.hairlineBorder,
    required this.ink,
    required this.mutedText,
    required this.accent,
    required this.available,
    required this.availableSurface,
    required this.borrowed,
    required this.borrowedSurface,
    required this.danger,
    required this.chipSelectedBg,
    required this.chipSelectedFg,
  });

  final Color canvas;
  final Color groupedCanvas;
  final Color cardSurface;
  final Color softSurface;
  final Color hairlineBorder;
  final Color ink;
  final Color mutedText;
  final Color accent;
  final Color available;
  final Color availableSurface;
  final Color borrowed;
  final Color borrowedSurface;
  final Color danger;
  final Color chipSelectedBg;
  final Color chipSelectedFg;

  static const light = BookNestColors(
    canvas: Color(0xFFFFFFFF),
    groupedCanvas: Color(0xFFF7F8FA),
    cardSurface: Color(0xFFFFFFFF),
    softSurface: Color(0xFFF3F4F6),
    hairlineBorder: Color(0xFFE5E7EB),
    ink: Color(0xFF111827),
    mutedText: Color(0xFF6B7280),
    accent: Color(0xFF4F46E5),
    available: Color(0xFF059669),
    availableSurface: Color(0xFFECFDF5),
    borrowed: Color(0xFFD97706),
    borrowedSurface: Color(0xFFFFFBEB),
    danger: Color(0xFFDC2626),
    chipSelectedBg: Color(0xFF111827),
    chipSelectedFg: Color(0xFFFFFFFF),
  );

  @override
  BookNestColors copyWith({
    Color? canvas,
    Color? groupedCanvas,
    Color? cardSurface,
    Color? softSurface,
    Color? hairlineBorder,
    Color? ink,
    Color? mutedText,
    Color? accent,
    Color? available,
    Color? availableSurface,
    Color? borrowed,
    Color? borrowedSurface,
    Color? danger,
    Color? chipSelectedBg,
    Color? chipSelectedFg,
  }) {
    return BookNestColors(
      canvas: canvas ?? this.canvas,
      groupedCanvas: groupedCanvas ?? this.groupedCanvas,
      cardSurface: cardSurface ?? this.cardSurface,
      softSurface: softSurface ?? this.softSurface,
      hairlineBorder: hairlineBorder ?? this.hairlineBorder,
      ink: ink ?? this.ink,
      mutedText: mutedText ?? this.mutedText,
      accent: accent ?? this.accent,
      available: available ?? this.available,
      availableSurface: availableSurface ?? this.availableSurface,
      borrowed: borrowed ?? this.borrowed,
      borrowedSurface: borrowedSurface ?? this.borrowedSurface,
      danger: danger ?? this.danger,
      chipSelectedBg: chipSelectedBg ?? this.chipSelectedBg,
      chipSelectedFg: chipSelectedFg ?? this.chipSelectedFg,
    );
  }

  @override
  BookNestColors lerp(ThemeExtension<BookNestColors>? other, double t) {
    if (other is! BookNestColors) return this;
    return BookNestColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      groupedCanvas: Color.lerp(groupedCanvas, other.groupedCanvas, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      softSurface: Color.lerp(softSurface, other.softSurface, t)!,
      hairlineBorder: Color.lerp(hairlineBorder, other.hairlineBorder, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      available: Color.lerp(available, other.available, t)!,
      availableSurface: Color.lerp(
        availableSurface,
        other.availableSurface,
        t,
      )!,
      borrowed: Color.lerp(borrowed, other.borrowed, t)!,
      borrowedSurface: Color.lerp(borrowedSurface, other.borrowedSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      chipSelectedBg: Color.lerp(chipSelectedBg, other.chipSelectedBg, t)!,
      chipSelectedFg: Color.lerp(chipSelectedFg, other.chipSelectedFg, t)!,
    );
  }
}

/// Centralized always-white editorial theme with native iOS motion and feel.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF4F46E5);

  static ThemeData light() {
    const tokens = BookNestColors.light;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    final colorScheme = baseScheme.copyWith(
      primary: tokens.accent,
      surface: tokens.cardSurface,
      onSurface: tokens.ink,
      error: tokens.danger,
      outlineVariant: tokens.hairlineBorder,
    );

    const cupertinoTransitions = PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      platform: TargetPlatform.iOS,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      pageTransitionsTheme: cupertinoTransitions,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: tokens.accent,
        scaffoldBackgroundColor: tokens.canvas,
        barBackgroundColor: const Color(0xEBFFFFFF),
      ),
      extensions: const <ThemeExtension<dynamic>>[tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: tokens.cardSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: tokens.hairlineBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.accent,
          foregroundColor: Colors.white,
          splashFactory: NoSplash.splashFactory,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.ink,
          splashFactory: NoSplash.splashFactory,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: tokens.hairlineBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          foregroundColor: tokens.accent,
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.softSurface,
        hintStyle: TextStyle(color: tokens.mutedText, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: tokens.hairlineBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: tokens.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: tokens.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: tokens.danger, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

/// Convenience getter for [BookNestColors] from any [BuildContext].
extension BookNestThemeContext on BuildContext {
  BookNestColors get bookNestColors =>
      Theme.of(this).extension<BookNestColors>() ?? BookNestColors.light;
}
