import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings xizmatini boshqaruvchi sinf
/// Bu sinf ilova sozlamalarini saqlash va boshqarish uchun ishlatiladi
class SettingsService with ChangeNotifier {
  // Private o'zgaruvchilar
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('uz', 'UZ');
  bool _isInitialized = false;

  // SharedPreferences instance
  SharedPreferences? _prefs;

  // Constants
  static const String _notificationsKey = 'notifications_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _themeModeKey = 'theme_mode';
  static const String _localeKey = 'locale';

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  /// Constructor
  SettingsService() {
    _initializeSettings();
  }

  /// Sozlamalarni boshlang'ich holga keltirish
  Future<void> _initializeSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Sozlamalarni yuklashda xatolik: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Barcha sozlamalarni yuklash
  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _notificationsEnabled = _prefs!.getBool(_notificationsKey) ?? true;
    _darkModeEnabled = _prefs!.getBool(_darkModeKey) ?? false;

    // Theme mode ni yuklash
    final themeModeIndex =
        _prefs!.getInt(_themeModeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex];

    // Locale ni yuklash
    final localeCode = _prefs!.getString(_localeKey) ?? 'uz';
    _locale = _parseLocale(localeCode);
  }

  /// Locale ni parse qilish
  Locale _parseLocale(String localeCode) {
    final parts = localeCode.split('_');
    if (parts.length >= 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  /// Locale ni string ga aylantirish
  String _localeToString(Locale locale) {
    return locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
  }

  /// Bildirishnomalar sozlamalarini o'zgartirish
  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (_prefs == null) return false;

    try {
      await _prefs!.setBool(_notificationsKey, enabled);
      _notificationsEnabled = enabled;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Bildirishnoma sozlamalarini saqlashda xatolik: $e');
      return false;
    }
  }

  /// Dark mode sozlamalarini o'zgartirish
  Future<bool> setDarkModeEnabled(bool enabled) async {
    if (_prefs == null) return false;

    try {
      await _prefs!.setBool(_darkModeKey, enabled);
      _darkModeEnabled = enabled;

      // Theme mode ni ham yangilash
      _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
      await _prefs!.setInt(_themeModeKey, _themeMode.index);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Dark mode sozlamalarini saqlashda xatolik: $e');
      return false;
    }
  }

  /// Theme mode ni o'zgartirish
  Future<bool> setThemeMode(ThemeMode themeMode) async {
    if (_prefs == null) return false;

    try {
      await _prefs!.setInt(_themeModeKey, themeMode.index);
      _themeMode = themeMode;

      // Dark mode flagini ham yangilash
      _darkModeEnabled = themeMode == ThemeMode.dark;
      await _prefs!.setBool(_darkModeKey, _darkModeEnabled);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Theme mode sozlamalarini saqlashda xatolik: $e');
      return false;
    }
  }

  /// Til sozlamalarini o'zgartirish
  Future<bool> setLocale(Locale locale) async {
    if (_prefs == null) return false;

    try {
      await _prefs!.setString(_localeKey, _localeToString(locale));
      _locale = locale;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Til sozlamalarini saqlashda xatolik: $e');
      return false;
    }
  }

  /// Barcha sozlamalarni standart holatga qaytarish
  Future<bool> resetAllSettings() async {
    if (_prefs == null) return false;

    try {
      await _prefs!.clear();

      // Standart qiymatlarni o'rnatish
      _notificationsEnabled = true;
      _darkModeEnabled = false;
      _themeMode = ThemeMode.system;
      _locale = const Locale('uz', 'UZ');

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sozlamalarni tiklashda xatolik: $e');
      return false;
    }
  }

  /// Theme mode ni toggle qilish
  Future<bool> toggleThemeMode() async {
    ThemeMode newTheme;

    switch (_themeMode) {
      case ThemeMode.light:
        newTheme = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newTheme = ThemeMode.system;
        break;
      case ThemeMode.system:
        newTheme = ThemeMode.light;
        break;
    }

    return await setThemeMode(newTheme);
  }

  /// Bildirishnomalarni toggle qilish
  Future<bool> toggleNotifications() async {
    return await setNotificationsEnabled(!_notificationsEnabled);
  }

  /// Sozlamalar to'g'risida ma'lumot olish
  Map<String, dynamic> getAllSettings() {
    return {
      'notificationsEnabled': _notificationsEnabled,
      'darkModeEnabled': _darkModeEnabled,
      'themeMode': _themeMode.toString(),
      'locale': _localeToString(_locale),
      'isInitialized': _isInitialized,
    };
  }
}
