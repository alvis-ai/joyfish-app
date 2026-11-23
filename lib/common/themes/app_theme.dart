import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bright, playful "candy" theme.
///
/// The legacy color names (cream, coral, peach, skyDeep, ...) are kept so the
/// pages that have not been redesigned yet keep compiling; their values now
/// map onto the candy palette so the whole app shifts together.
class AppTheme {
  // ---- Candy palette -------------------------------------------------------
  static const Color candyPink = Color(0xFFFF5C8A);
  static const Color candyPinkSoft = Color(0xFFFFD6E2);
  static const Color lemon = Color(0xFFFFD23F);
  static const Color lemonSoft = Color(0xFFFFF1B8);
  static const Color skyBlue = Color(0xFF3EC1F3);
  static const Color skySoft = Color(0xFFD5F1FD);
  static const Color mint = Color(0xFF3DCB98);
  static const Color mintSoft = Color(0xFFD3F5E8);
  static const Color grape = Color(0xFF8B6CFF);
  static const Color grapeSoft = Color(0xFFE7E0FF);
  static const Color navy = Color(0xFF1B2A4A);
  static const Color navyMuted = Color(0xFF5B6B8C);
  static const Color background = Color(0xFFEAF6FF);
  static const Color fieldStroke = Color(0xFFCFE0F0);

  // ---- Legacy names, remapped onto the candy palette -----------------------
  static const Color cream = Color(0xFFF3FAFF);
  static const Color pageTint = skySoft;
  static const Color pageLavender = lemonSoft;
  static const Color sky = skyBlue;
  static const Color skyDeep = Color(0xFF1479B8);
  static const Color leaf = mint;
  static const Color peach = lemon;
  static const Color coral = candyPink;
  static const Color ink = navy;
  static const Color mutedInk = navyMuted;
  static const Color purple = grape;
  static const Color purpleLight = grapeSoft;
  static const Color olive = Color(0xFF2D4470);
  static const Color card = Colors.white;
  static const Color border = navy;
  static const Color softStroke = fieldStroke;

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDDF1FF), Color(0xFFF4FBFF)],
  );

  /// Thick outline used by "sticker" surfaces.
  static Border stickerBorder({Color color = navy, double? width}) =>
      Border.all(color: color, width: width ?? 2.5);

  /// Solid, blur-free drop shadow that makes a surface look like a sticker.
  static List<BoxShadow> stickerShadow({
    Color color = navy,
    double offset = 5,
  }) => [BoxShadow(color: color, offset: Offset(0, offset), blurRadius: 0)];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: candyPink,
        secondary: lemon,
        tertiary: skyBlue,
        surface: card,
        error: Color(0xFFE5484D),
        onPrimary: Colors.white,
        onSecondary: navy,
        onSurface: navy,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 34.sp,
          fontWeight: FontWeight.w900,
          color: navy,
        ),
        displayMedium: TextStyle(
          fontSize: 30.sp,
          fontWeight: FontWeight.w900,
          color: navy,
        ),
        displaySmall: TextStyle(
          fontSize: 26.sp,
          fontWeight: FontWeight.w900,
          color: navy,
        ),
        headlineLarge: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
        headlineMedium: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
        headlineSmall: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
          color: navy,
        ),
        bodyLarge: TextStyle(fontSize: 16.sp, color: navy, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14.sp, color: navy, height: 1.45),
        bodySmall: TextStyle(fontSize: 12.sp, color: navyMuted),
        labelLarge: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: navy,
        ),
        labelMedium: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: navyMuted,
        ),
        labelSmall: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: navyMuted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: candyPink,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.r),
            side: const BorderSide(color: navy, width: 2.5),
          ),
          textStyle: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: candyPink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFFFC4D4),
          disabledForegroundColor: Colors.white,
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28.r),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: fieldStroke, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: fieldStroke, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: candyPink, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: Color(0xFFE5484D), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: const BorderSide(color: Color(0xFFE5484D), width: 2.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        hintStyle: TextStyle(
          color: const Color(0xFF8D9AB5),
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: TextStyle(
          color: navyMuted,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? candyPink : Colors.white,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: navy, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
          side: const BorderSide(color: navy, width: 2.5),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
      dividerTheme: const DividerThemeData(color: fieldStroke, thickness: 1.5),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: candyPink,
        unselectedItemColor: navyMuted,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.r),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? candyPink
              : const Color(0xFFCFD8E8),
        ),
      ),
    );
  }
}
