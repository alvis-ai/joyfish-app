import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  static const Color cream = Color(0xFFFBF8EF);
  static const Color pageTint = Color(0xFFFFF2D4);
  static const Color pageLavender = Color(0xFFEAF5FF);
  static const Color sky = Color(0xFF8CDDF1);
  static const Color skyDeep = Color(0xFF0A7BC2);
  static const Color leaf = Color(0xFF9AF66A);
  static const Color peach = Color(0xFFFFD83D);
  static const Color coral = Color(0xFFFF7A3D);
  static const Color ink = Color(0xFF111827);
  static const Color mutedInk = Color(0xFF817B68);
  static const Color purple = Color(0xFF7A39D8);
  static const Color purpleLight = Color(0xFF69B6F7);
  static const Color olive = Color(0xFF6E5A00);
  static const Color card = Colors.white;
  static const Color border = Color(0xFF111827);
  static const Color softStroke = Color(0xFFD8D0BD);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCF8EE), Color(0xFFFBF8EF)],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: skyDeep,
        secondary: peach,
        tertiary: leaf,
        surface: card,
        error: Color(0xFFE0564A),
        onPrimary: Colors.white,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: TextTheme(
        displayLarge:
            TextStyle(fontSize: 34.sp, fontWeight: FontWeight.w900, color: ink),
        displayMedium:
            TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w900, color: ink),
        displaySmall:
            TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: ink),
        headlineLarge:
            TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w900, color: ink),
        headlineMedium:
            TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: ink),
        headlineSmall:
            TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: TextStyle(fontSize: 16.sp, color: ink),
        bodyMedium: TextStyle(fontSize: 14.sp, color: ink),
        bodySmall: TextStyle(fontSize: 12.sp, color: mutedInk),
        labelLarge:
            TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: ink),
        labelMedium: TextStyle(
            fontSize: 12.sp, fontWeight: FontWeight.w500, color: mutedInk),
        labelSmall: TextStyle(
            fontSize: 10.sp, fontWeight: FontWeight.w500, color: mutedInk),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: peach,
          foregroundColor: ink,
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
            side: const BorderSide(color: ink, width: 2.2),
          ),
          textStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: ink, width: 2.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: softStroke, width: 2.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.r),
          borderSide: const BorderSide(color: ink, width: 2.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: Color(0xFFE0564A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: Color(0xFFE0564A), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        hintStyle: TextStyle(
            color: mutedInk, fontSize: 14.sp, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(
            color: mutedInk, fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
          side: const BorderSide(color: Colors.transparent),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
      dividerTheme: const DividerThemeData(color: softStroke, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: skyDeep,
        unselectedItemColor: mutedInk,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle:
            TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14.sp),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return purpleLight;
          }
          return const Color(0xFFD3D8E5);
        }),
      ),
    );
  }
}
