import 'package:flutter/material.dart';

import 'paleta.dart';

ThemeData construirTema() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Paleta.esmeralda,
        brightness: Brightness.dark,
      ).copyWith(
        primary: Paleta.esmeralda,
        onPrimary: Colors.black,
        secondary: Paleta.menta,
        onSecondary: Colors.black,
        tertiary: Paleta.lima,
        onTertiary: Colors.black,
        surface: Paleta.superficie,
        onSurface: const Color(0xFFE8F2EC),
        error: Paleta.gasto,
        outline: Paleta.textoSuave,
        outlineVariant: Colors.white12,
        secondaryContainer: const Color(0xFF16322B),
        onSecondaryContainer: Paleta.menta,
      );

  OutlineInputBorder borde(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: w),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Paleta.fondo,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: borde(Colors.white12),
      enabledBorder: borde(Colors.white12),
      focusedBorder: borde(Paleta.esmeralda, 1.5),
      errorBorder: borde(Paleta.gasto),
      focusedErrorBorder: borde(Paleta.gasto, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Paleta.lima,
        foregroundColor: Colors.black,
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Paleta.fondo,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Paleta.esmeralda.withValues(alpha: 0.18),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Paleta.fondo,
      indicatorColor: Paleta.esmeralda.withValues(alpha: 0.18),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Color(0xFF1B2622),
    ),
    chipTheme: ChipThemeData(
      showCheckmark: false,
      side: const BorderSide(color: Colors.white12),
      selectedColor: Paleta.esmeralda.withValues(alpha: 0.22),
    ),
  );
}
