import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token warna dari design system ScanScript.
class AppColors {
  static const brand = Color(0xFF3B82F6); // swatch Primary (aksen terang)
  static const primary = Color(0xFF0058BE); // warna tombol / aksi utama
  static const secondary = Color(0xFFEFF3F8); // background app
  static const tertiary = Color(0xFF6E6446); // olive (tag, ikon, flag)
  static const tertiaryContainer = Color(0xFFFFF0C9);
  static const neutral = Color(0xFF171717);
  static const neutralMid = Color(0xFF55585C);
  static const inverted = Color(0xFF2B2B2B);
  static const buttonGray = Color(0xFFE9E8E7);
  static const outline = Color(0xFFC4C4C4);
  static const outlineSoft = Color(0xFFE2E6EC);
  static const error = Color(0xFFBF1E1E);
}

class AppRadius {
  static const button = 2.0; // tombol & input: kotak tajam
  static const card = 24.0; // kartu / tile
}

class AppDecor {
  static BoxDecoration card({Color color = Colors.white}) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(AppRadius.card),
    border: Border.all(color: AppColors.outlineSoft),
  );
}

/// Varian tombol di luar default (Primary = FilledButton, Outlined = OutlinedButton).
class AppButtons {
  static final secondary = FilledButton.styleFrom(
    backgroundColor: AppColors.buttonGray,
    foregroundColor: AppColors.neutral,
  );
  static final inverted = FilledButton.styleFrom(
    backgroundColor: AppColors.inverted,
    foregroundColor: Colors.white,
  );
  static final danger = FilledButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
  );
}

class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.neutralMid,
      onSecondary: Colors.white,
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.tertiary,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.secondary,
      onSurface: AppColors.neutral,
      onSurfaceVariant: AppColors.neutralMid,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineSoft,
      surfaceContainerHighest: AppColors.buttonGray,
    );

    // Body & label = Geist, headline = Space Grotesk.
    // Body & label = Geist (bundle), headline = Space Grotesk (google_fonts).
    final base = ThemeData.light().textTheme.apply(
      fontFamily: 'Geist',
      bodyColor: AppColors.neutral,
      displayColor: AppColors.neutral,
    );
    TextStyle? head(TextStyle? s) =>
        GoogleFonts.spaceGrotesk(textStyle: s, fontWeight: FontWeight.w600);
    final text = base.copyWith(
      displayLarge: head(base.displayLarge),
      displayMedium: head(base.displayMedium),
      displaySmall: head(base.displaySmall),
      headlineLarge: head(base.headlineLarge),
      headlineMedium: head(base.headlineMedium),
      headlineSmall: head(base.headlineSmall),
      titleLarge: head(base.titleLarge),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
    const label = TextStyle(
      fontFamily: 'Geist',
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    const minSize = Size(0, 52);

    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
      borderSide: BorderSide(color: c, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.secondary,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.neutral,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 20),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9DB9E0),
          disabledForegroundColor: Colors.white,
          minimumSize: minSize,
          shape: shape,
          textStyle: label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.neutral,
          minimumSize: minSize,
          shape: shape,
          side: const BorderSide(color: Color(0xFF8C8C8C), width: 1.5),
          textStyle: label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: shape,
          textStyle: label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.buttonGray,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: AppColors.neutralMid),
        border: border(AppColors.outline),
        enabledBorder: border(AppColors.outline),
        focusedBorder: border(AppColors.primary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.inverted,
        contentTextStyle: const TextStyle(
          fontFamily: 'Geist',
          color: Colors.white,
          fontSize: 14,
        ),
        shape: shape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFE3E3E3),
        linearMinHeight: 6,
      ),
    );
  }
}
