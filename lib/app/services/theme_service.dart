import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  light,
  dark,
  blue,
  green,
  purple,
  orange,
  pink,
  teal,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  AppTheme _currentTheme = AppTheme.blue;
  bool _isDarkMode = false;

  AppTheme get currentTheme => _currentTheme;
  bool get isDarkMode => _isDarkMode;

  Future<void> initialize() async {
    await _loadTheme();
  }

  // Mavzuni o'zgartirish
  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _saveTheme();
    notifyListeners();
  }

  // Dark/Light mode
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _saveTheme();
    notifyListeners();
  }

  // Mavzu ma'lumotlarini olish
  ThemeData getThemeData() {
    final colorScheme = _getColorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withValues(alpha: 0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.2),
        thickness: 1,
      ),
    );
  }

  // Rang sxemasini olish
  ColorScheme _getColorScheme() {
    Color primaryColor;

    switch (_currentTheme) {
      case AppTheme.light:
        primaryColor = Colors.blue;
        break;
      case AppTheme.dark:
        primaryColor = Colors.blue;
        break;
      case AppTheme.blue:
        primaryColor = Colors.blue;
        break;
      case AppTheme.green:
        primaryColor = Colors.green;
        break;
      case AppTheme.purple:
        primaryColor = Colors.purple;
        break;
      case AppTheme.orange:
        primaryColor = Colors.orange;
        break;
      case AppTheme.pink:
        primaryColor = Colors.pink;
        break;
      case AppTheme.teal:
        primaryColor = Colors.teal;
        break;
    }

    if (_isDarkMode) {
      return ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      );
    } else {
      return ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      );
    }
  }

  // Mavzu nomini olish
  String getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Yorug\'';
      case AppTheme.dark:
        return 'Qorong\'u';
      case AppTheme.blue:
        return 'Ko\'k';
      case AppTheme.green:
        return 'Yashil';
      case AppTheme.purple:
        return 'Binafsha';
      case AppTheme.orange:
        return 'To\'q sariq';
      case AppTheme.pink:
        return 'Pushti';
      case AppTheme.teal:
        return 'Ko\'k-yashil';
    }
  }

  // Mavzu rangini olish
  Color getThemeColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Colors.blue;
      case AppTheme.dark:
        return Colors.blue;
      case AppTheme.blue:
        return Colors.blue;
      case AppTheme.green:
        return Colors.green;
      case AppTheme.purple:
        return Colors.purple;
      case AppTheme.orange:
        return Colors.orange;
      case AppTheme.pink:
        return Colors.pink;
      case AppTheme.teal:
        return Colors.teal;
    }
  }

  // Barcha mavzular ro'yxati
  List<AppTheme> get availableThemes => AppTheme.values;

  // Saqlash va yuklash
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', _currentTheme.toString());
    await prefs.setBool('is_dark_mode', _isDarkMode);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final themeString = prefs.getString('app_theme');
    if (themeString != null) {
      _currentTheme = AppTheme.values.firstWhere(
        (theme) => theme.toString() == themeString,
        orElse: () => AppTheme.blue,
      );
    }

    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  // Gradient ranglar
  LinearGradient getThemeGradient() {
    final color = getThemeColor(_currentTheme);
    return LinearGradient(
      colors: [
        color,
        color.withValues(alpha: 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Mavzu uchun ikonka
  IconData getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.blue:
        return Icons.water_drop;
      case AppTheme.green:
        return Icons.eco;
      case AppTheme.purple:
        return Icons.auto_awesome;
      case AppTheme.orange:
        return Icons.wb_sunny;
      case AppTheme.pink:
        return Icons.favorite;
      case AppTheme.teal:
        return Icons.waves;
    }
  }
}
