import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const primaryColor = Color(0xFF254FD5);
  static const primaryLight = Color(0xFFEEF2FF);
  static const accentColor = Color(0xFF254FD5);
  static const successColor = Color(0xFF117C6F);
  static const warningColor = Color(0xFF8C5A12);
  static const backgroundColor = Color(0xFFF3F6FC);
  static const cardColor = Colors.white;
  static const textPrimary = Color(0xFF17213A);
  static const textSecondary = Color(0xFF52617E);
  static const textLight = Color(0xFF65708A);
  static const dividerColor = Color(0xFFE1E7F2);
  static const spacingXs = 4.0,
      spacingSm = 8.0,
      spacingMd = 20.0,
      spacingLg = 28.0,
      spacingXl = 36.0;
  static const radiusSm = 8.0,
      radiusMd = 14.0,
      radiusLg = 20.0,
      radiusXl = 28.0;
  static const heading1 = TextStyle(
    fontFamily: 'Noto Sans CJK SC',
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.25,
  );
  static const heading2 = TextStyle(
    fontFamily: 'Noto Sans CJK SC',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.35,
  );
  static const heading3 = TextStyle(
    fontFamily: 'Noto Sans CJK SC',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.4,
  );
  static const bodyLarge = TextStyle(
    fontFamily: 'Noto Sans CJK SC',
    fontSize: 17,
    color: textPrimary,
    height: 1.6,
  );
  static const body = TextStyle(
    fontFamily: 'Noto Sans CJK SC',
    fontSize: 15,
    color: textPrimary,
    height: 1.6,
  );
  static const bodySmall = TextStyle(
    fontFamily: 'Noto Sans CJK SC',
    fontSize: 13,
    color: textSecondary,
    height: 1.55,
  );
  static const caption = TextStyle(
    fontFamily: 'Noto Sans CJK SC',
    fontSize: 12,
    color: textSecondary,
    height: 1.5,
  );
  static const tagStyle = TextStyle(
    fontFamily: 'Noto Sans CJK SC',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );
  static const List<BoxShadow> cardShadow = [];
  static const List<BoxShadow> elevatedShadow = [];
  static Color getCategoryColor(String category) => primaryColor;
  static Color getIndustryColor(String industry) => primaryColor;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Noto Sans CJK SC',
    fontFamilyFallback: const ['sans-serif'],
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: successColor,
      surface: cardColor,
      onSurface: textPrimary,
      error: Color(0xFFB3261E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: heading3,
    ),
    textTheme: const TextTheme(
      bodyMedium: body,
      bodySmall: bodySmall,
      titleMedium: heading3,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: primaryLight,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Noto Sans CJK SC',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? primaryColor
              : textSecondary,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        minimumSize: const Size(48, 48),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      hintStyle: bodySmall,
    ),
    iconTheme: const IconThemeData(color: textSecondary),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: primaryLight,
      secondarySelectedColor: primaryLight,
      showCheckmark: false,
      side: const BorderSide(color: dividerColor),
      labelStyle: bodySmall,
      secondaryLabelStyle: bodySmall.copyWith(
        color: primaryColor,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    tabBarTheme: const TabBarThemeData(dividerColor: dividerColor),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),
  );
  static ThemeData get darkTheme => lightTheme;
}
