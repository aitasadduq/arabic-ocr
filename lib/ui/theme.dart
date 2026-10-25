import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Warm paper and ink, with the green "nuqta" dot as the accent.
abstract final class AppTheme {
  static const uiFont = 'IBMPlexSans';
  static const arabicUiFont = 'NotoSansArabic';
  static const displayFont = 'SourceSerif4';
  static const readingFont = 'NotoNaskhArabic';

  static const _light = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2E7D5B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFCDEBDC),
    onPrimaryContainer: Color(0xFF0E3B28),
    secondary: Color(0xFF6B5E4B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFEDE3D3),
    onSecondaryContainer: Color(0xFF2B2216),
    tertiary: Color(0xFF8A5A2B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF6DEC4),
    onTertiaryContainer: Color(0xFF331B04),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFF4F1EA),
    onSurface: Color(0xFF1C1B19),
    onSurfaceVariant: Color(0xFF5F5A52),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF9F7F2),
    surfaceContainer: Color(0xFFEFEBE3),
    surfaceContainerHigh: Color(0xFFE9E4DB),
    surfaceContainerHighest: Color(0xFFE2DCD1),
    outline: Color(0xFFB9B1A4),
    outlineVariant: Color(0xFFDDD6CA),
    inverseSurface: Color(0xFF32302C),
    onInverseSurface: Color(0xFFF4F1EA),
    inversePrimary: Color(0xFF7CCBA3),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const _dark = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF7CCBA3),
    onPrimary: Color(0xFF003822),
    primaryContainer: Color(0xFF1F4F3A),
    onPrimaryContainer: Color(0xFFBDEBD3),
    secondary: Color(0xFFD6C6AE),
    onSecondary: Color(0xFF3A3020),
    secondaryContainer: Color(0xFF4A3F2F),
    onSecondaryContainer: Color(0xFFF1E3CC),
    tertiary: Color(0xFFE8BC8C),
    onTertiary: Color(0xFF4A2A07),
    tertiaryContainer: Color(0xFF66401B),
    onTertiaryContainer: Color(0xFFFFDDBA),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF151412),
    onSurface: Color(0xFFECE7DF),
    onSurfaceVariant: Color(0xFFB3ACA1),
    surfaceContainerLowest: Color(0xFF0F0E0D),
    surfaceContainerLow: Color(0xFF1B1A17),
    surfaceContainer: Color(0xFF211F1C),
    surfaceContainerHigh: Color(0xFF2A2824),
    surfaceContainerHighest: Color(0xFF34312C),
    outline: Color(0xFF7D766C),
    outlineVariant: Color(0xFF433F39),
    inverseSurface: Color(0xFFECE7DF),
    onInverseSurface: Color(0xFF32302C),
    inversePrimary: Color(0xFF2E7D5B),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static ThemeData light(Locale locale) => _build(_light, locale);
  static ThemeData dark(Locale locale) => _build(_dark, locale);

  static ThemeData _build(ColorScheme cs, Locale locale) {
    final arabic = locale.languageCode == 'ar';
    final family = arabic ? arabicUiFont : uiFont;
    final fallback = arabic ? const [uiFont] : const [arabicUiFont];
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      fontFamily: family,
      fontFamilyFallback: fallback,
    );
    final t = base.textTheme;
    TextStyle display(TextStyle? s, {FontWeight w = FontWeight.w600}) =>
        s!.copyWith(
          fontFamily: arabic ? readingFont : displayFont,
          fontFamilyFallback: const [readingFont, displayFont],
          fontWeight: w,
          letterSpacing: arabic ? 0 : -0.5,
          height: arabic ? 1.35 : 1.1,
        );
    final text = t.copyWith(
      displayLarge: display(t.displayLarge),
      displayMedium: display(t.displayMedium),
      displaySmall: display(t.displaySmall),
      headlineLarge: display(t.headlineLarge),
      headlineMedium: display(t.headlineMedium),
      headlineSmall: display(t.headlineSmall),
      titleLarge: t.titleLarge!.copyWith(fontWeight: FontWeight.w600),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: cs.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: cs.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: shape,
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: shape,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: cs.primaryContainer,
          selectedForegroundColor: cs.onPrimaryContainer,
          minimumSize: const Size(0, 44),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: cs.outlineVariant),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// The style for text the model read.
  static TextStyle reading(BuildContext context, double scale) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: readingFont,
      fontFamilyFallback: const [arabicUiFont, uiFont],
      fontSize: 19 * scale,
      height: 1.85,
      color: cs.onSurface,
    );
  }
}
