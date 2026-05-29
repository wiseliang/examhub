import 'package:flutter/material.dart';

/// App主题配置 - 内容丰富型（参考小红书+知乎风格）
class AppTheme {
  // ==================== 配色方案 ====================

  /// 主色 - 深蓝（专业/信任感）
  static const Color primaryColor = Color(0xFF1A5276);

  /// 主色浅变体
  static const Color primaryLight = Color(0xFF2980B9);

  /// 强调色 - 暖橙金（用于星级/标签/CTA按钮）
  static const Color accentColor = Color(0xFFF39C12);

  /// 成功色
  static const Color successColor = Color(0xFF27AE60);

  /// 警告色
  static const Color warningColor = Color(0xFFE74C3C);

  /// 背景色
  static const Color backgroundColor = Color(0xFFF5F6FA);

  /// 卡片背景
  static const Color cardColor = Colors.white;

  /// 主文字色
  static const Color textPrimary = Color(0xFF2C3E50);

  /// 次文字色
  static const Color textSecondary = Color(0xFF7F8C8D);

  /// 浅灰文字
  static const Color textLight = Color(0xFFBDC3C7);

  /// 分割线
  static const Color dividerColor = Color(0xFFECF0F1);

  // ==================== 分类颜色映射 ====================

  static const Map<String, Color> categoryColors = {
    '准入类': Color(0xFFE74C3C),       // 红色（重要）
    '水平评价类': Color(0xFF2980B9),    // 蓝色
    '国际认证': Color(0xFF8E44AD),      // 紫色
    '企业认证': Color(0xFF27AE60),      // 绿色
    '技能等级认定': Color(0xFFF39C12),  // 橙色
  };

  static const Map<String, Color> industryColors = {
    '财会金融': Color(0xFFE74C3C),
    '法律': Color(0xFF8E44AD),
    '建筑地产': Color(0xFFD35400),
    '医疗健康': Color(0xFF27AE60),
    '教育培训': Color(0xFF2980B9),
    'IT互联网': Color(0xFF3498DB),
    '公共管理': Color(0xFF16A085),
  };

  /// 获取分类颜色
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? primaryColor;
  }

  /// 获取行业颜色
  static Color getIndustryColor(String industry) {
    return industryColors[industry] ?? primaryColor;
  }

  // ==================== 文本样式 ====================

  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textLight,
    height: 1.3,
  );

  static const TextStyle tagStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: primaryColor,
    height: 1.0,
  );

  // ==================== 间距 ====================

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // ==================== 圆角 ====================

  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ==================== 阴影 ====================

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ==================== App主题 ====================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        surface: cardColor,
        error: warningColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor.withValues(alpha: 0.1),
        labelStyle: const TextStyle(fontSize: 12, color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryLight,
      scaffoldBackgroundColor: const Color(0xFF1A1A2E),
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        onPrimary: Colors.white,
        secondary: accentColor,
        surface: Color(0xFF16213E),
        error: warningColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16213E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF16213E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF16213E),
        selectedItemColor: primaryLight,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
