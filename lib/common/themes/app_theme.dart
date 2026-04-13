import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  static const Color cream = Color(0xFFFFF7F0);
  static const Color pageTint = Color(0xFFF8E1EB);
  static const Color pageLavender = Color(0xFFE9D7FF);
  static const Color sky = Color(0xFF73C6FF);
  static const Color skyDeep = Color(0xFF5398F5);
  static const Color leaf = Color(0xFF17B57D);
  static const Color peach = Color(0xFFFFB000);
  static const Color coral = Color(0xFFFF7B53);
  static const Color ink = Color(0xFF2D3448);
  static const Color mutedInk = Color(0xFFA1A5B5);
  static const Color purple = Color(0xFF7A39D8);
  static const Color purpleLight = Color(0xFFA96BFF);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE5E1EA);
  static const Color softStroke = Color(0xFFE3E5EF);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF6E9), Color(0xFFFCE0EA), Color(0xFFE0C9F8)],
    stops: [0.0, 0.58, 1.0],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: purple,
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
        foregroundColor: purple,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: purple,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 34.sp, fontWeight: FontWeight.w800, color: purple),
        displayMedium: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w800, color: purple),
        displaySmall: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800, color: purple),
        headlineLarge: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800, color: ink),
        headlineMedium: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: ink),
        headlineSmall: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: TextStyle(fontSize: 16.sp, color: ink),
        bodyMedium: TextStyle(fontSize: 14.sp, color: ink),
        bodySmall: TextStyle(fontSize: 12.sp, color: mutedInk),
        labelLarge: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: ink),
        labelMedium: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: mutedInk),
        labelSmall: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, color: mutedInk),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
          textStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7EFF2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: softStroke, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: softStroke, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: purpleLight, width: 1.8),
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
        hintStyle: TextStyle(color: mutedInk, fontSize: 14.sp, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(color: mutedInk, fontSize: 14.sp, fontWeight: FontWeight.w500),
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
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: purple,
        unselectedItemColor: mutedInk,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14.sp),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
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
