import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  uzbekLatin,
  uzbekCyrillic,
  russian,
  english,
}

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  AppLanguage _currentLanguage = AppLanguage.uzbekLatin;
  Map<String, String> _translations = {};

  AppLanguage get currentLanguage => _currentLanguage;
  Locale get currentLocale => _getLocale(_currentLanguage);

  Future<void> initialize() async {
    await _loadLanguage();
    await _loadTranslations();
  }

  // Tilni o'zgartirish
  Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;
    await _loadTranslations();
    await _saveLanguage();
    notifyListeners();
  }

  // Tarjimani olish
  String translate(String key) {
    return _translations[key] ?? key;
  }

  // Qisqa usul
  String t(String key) => translate(key);

  // Locale olish
  Locale _getLocale(AppLanguage language) {
    switch (language) {
      case AppLanguage.uzbekLatin:
        return const Locale('uz', 'UZ');
      case AppLanguage.uzbekCyrillic:
        return const Locale('uz', 'CY');
      case AppLanguage.russian:
        return const Locale('ru', 'RU');
      case AppLanguage.english:
        return const Locale('en', 'US');
    }
  }

  // Til nomini olish
  String getLanguageName(AppLanguage language) {
    switch (language) {
      case AppLanguage.uzbekLatin:
        return 'O\'zbekcha (Lotin)';
      case AppLanguage.uzbekCyrillic:
        return 'Ўзбекча (Кирилл)';
      case AppLanguage.russian:
        return 'Русский';
      case AppLanguage.english:
        return 'English';
    }
  }

  // Til bayrog'ini olish
  String getLanguageFlag(AppLanguage language) {
    switch (language) {
      case AppLanguage.uzbekLatin:
      case AppLanguage.uzbekCyrillic:
        return '🇺🇿';
      case AppLanguage.russian:
        return '🇷🇺';
      case AppLanguage.english:
        return '🇺🇸';
    }
  }

  // Barcha tillar ro'yxati
  List<AppLanguage> get availableLanguages => AppLanguage.values;

  // Tarjimalarni yuklash
  Future<void> _loadTranslations() async {
    switch (_currentLanguage) {
      case AppLanguage.uzbekLatin:
        _translations = _uzbekLatinTranslations;
        break;
      case AppLanguage.uzbekCyrillic:
        _translations = _uzbekCyrillicTranslations;
        break;
      case AppLanguage.russian:
        _translations = _russianTranslations;
        break;
      case AppLanguage.english:
        _translations = _englishTranslations;
        break;
    }
  }

  // Saqlash va yuklash
  Future<void> _saveLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', _currentLanguage.toString());
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageString = prefs.getString('app_language');
    
    if (languageString != null) {
      _currentLanguage = AppLanguage.values.firstWhere(
        (lang) => lang.toString() == languageString,
        orElse: () => AppLanguage.uzbekLatin,
      );
    }
  }

  // O'zbek (Lotin) tarjimalari
  static const Map<String, String> _uzbekLatinTranslations = {
    // Asosiy
    'app_name': 'Qadam App',
    'welcome': 'Xush kelibsiz',
    'hello': 'Salom',
    'yes': 'Ha',
    'no': 'Yo\'q',
    'ok': 'OK',
    'cancel': 'Bekor qilish',
    'save': 'Saqlash',
    'delete': 'O\'chirish',
    'edit': 'Tahrirlash',
    'loading': 'Yuklanmoqda...',
    'error': 'Xatolik',
    'success': 'Muvaffaqiyat',
    'retry': 'Qayta urinish',
    
    // Navigation
    'home': 'Bosh sahifa',
    'profile': 'Profil',
    'challenges': 'Vazifalar',
    'ranking': 'Reyting',
    'shop': 'Do\'kon',
    'settings': 'Sozlamalar',
    'statistics': 'Statistikalar',
    'friends': 'Do\'stlar',
    'achievements': 'Yutuqlar',
    
    // Steps
    'steps': 'Qadamlar',
    'daily_steps': 'Kunlik qadamlar',
    'total_steps': 'Jami qadamlar',
    'steps_today': 'Bugungi qadamlar',
    'steps_goal': 'Qadamlar maqsadi',
    'steps_remaining': 'Qolgan qadamlar',
    
    // Coins
    'coins': 'Tangalar',
    'total_coins': 'Jami tangalar',
    'coins_earned': 'Topilgan tangalar',
    'coins_spent': 'Sarflangan tangalar',
    'earn_coins': 'Tanga toplash',
    
    // Challenges
    'daily_challenges': 'Kunlik vazifalar',
    'weekly_challenges': 'Haftalik vazifalar',
    'challenge_completed': 'Vazifa bajarildi',
    'challenge_progress': 'Vazifa jarayoni',
    'complete_challenge': 'Vazifani bajarish',
    
    // Level
    'level': 'Daraja',
    'current_level': 'Joriy daraja',
    'next_level': 'Keyingi daraja',
    'level_up': 'Daraja oshdi',
    'experience': 'Tajriba',
    'xp': 'XP',
    
    // Social
    'add_friend': 'Do\'st qo\'shish',
    'friend_requests': 'Do\'stlik so\'rovlari',
    'online_friends': 'Onlayn do\'stlar',
    'leaderboard': 'Reyting jadvali',
    'share': 'Ulashish',
    
    // Settings
    'theme': 'Mavzu',
    'language': 'Til',
    'notifications': 'Bildirishnomalar',
    'privacy': 'Maxfiylik',
    'about': 'Dastur haqida',
    'logout': 'Chiqish',
    
    // Notifications
    'daily_reminder': 'Kunlik eslatma',
    'challenge_alerts': 'Vazifa ogohlantirishlari',
    'achievement_notifications': 'Yutuq bildirishnomalari',
    
    // Time
    'today': 'Bugun',
    'yesterday': 'Kecha',
    'this_week': 'Bu hafta',
    'this_month': 'Bu oy',
    'all_time': 'Barcha vaqt',
  };

  // O'zbek (Kirill) tarjimalari
  static const Map<String, String> _uzbekCyrillicTranslations = {
    'app_name': 'Қадам App',
    'welcome': 'Хуш келибсиз',
    'hello': 'Салом',
    'yes': 'Ҳа',
    'no': 'Йўқ',
    'ok': 'OK',
    'cancel': 'Бекор қилиш',
    'save': 'Сақлаш',
    'delete': 'Ўчириш',
    'edit': 'Таҳрирлаш',
    'loading': 'Юкланмоқда...',
    'error': 'Хатолик',
    'success': 'Муваффақият',
    'retry': 'Қайта уриниш',
    
    'home': 'Бош саҳифа',
    'profile': 'Профил',
    'challenges': 'Вазифалар',
    'ranking': 'Рейтинг',
    'shop': 'Дўкон',
    'settings': 'Созламалар',
    'statistics': 'Статистикалар',
    'friends': 'Дўстлар',
    'achievements': 'Ютуқлар',
    
    'steps': 'Қадамлар',
    'daily_steps': 'Кунлик қадамлар',
    'total_steps': 'Жами қадамлар',
    'steps_today': 'Бугунги қадамлар',
    'steps_goal': 'Қадамлар мақсади',
    'steps_remaining': 'Қолган қадамлар',
    
    'coins': 'Танғалар',
    'total_coins': 'Жами танғалар',
    'coins_earned': 'Топилган танғалар',
    'coins_spent': 'Сарфланган танғалар',
    'earn_coins': 'Танға топлаш',
  };

  // Rus tarjimalari
  static const Map<String, String> _russianTranslations = {
    'app_name': 'Шаг App',
    'welcome': 'Добро пожаловать',
    'hello': 'Привет',
    'yes': 'Да',
    'no': 'Нет',
    'ok': 'OK',
    'cancel': 'Отмена',
    'save': 'Сохранить',
    'delete': 'Удалить',
    'edit': 'Редактировать',
    'loading': 'Загрузка...',
    'error': 'Ошибка',
    'success': 'Успех',
    'retry': 'Повторить',
    
    'home': 'Главная',
    'profile': 'Профиль',
    'challenges': 'Задания',
    'ranking': 'Рейтинг',
    'shop': 'Магазин',
    'settings': 'Настройки',
    'statistics': 'Статистика',
    'friends': 'Друзья',
    'achievements': 'Достижения',
    
    'steps': 'Шаги',
    'daily_steps': 'Дневные шаги',
    'total_steps': 'Всего шагов',
    'steps_today': 'Шаги сегодня',
    'steps_goal': 'Цель шагов',
    'steps_remaining': 'Осталось шагов',
    
    'coins': 'Монеты',
    'total_coins': 'Всего монет',
    'coins_earned': 'Заработано монет',
    'coins_spent': 'Потрачено монет',
    'earn_coins': 'Заработать монеты',
  };

  // Ingliz tarjimalari
  static const Map<String, String> _englishTranslations = {
    'app_name': 'Step App',
    'welcome': 'Welcome',
    'hello': 'Hello',
    'yes': 'Yes',
    'no': 'No',
    'ok': 'OK',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'loading': 'Loading...',
    'error': 'Error',
    'success': 'Success',
    'retry': 'Retry',
    
    'home': 'Home',
    'profile': 'Profile',
    'challenges': 'Challenges',
    'ranking': 'Ranking',
    'shop': 'Shop',
    'settings': 'Settings',
    'statistics': 'Statistics',
    'friends': 'Friends',
    'achievements': 'Achievements',
    
    'steps': 'Steps',
    'daily_steps': 'Daily Steps',
    'total_steps': 'Total Steps',
    'steps_today': 'Steps Today',
    'steps_goal': 'Steps Goal',
    'steps_remaining': 'Steps Remaining',
    
    'coins': 'Coins',
    'total_coins': 'Total Coins',
    'coins_earned': 'Coins Earned',
    'coins_spent': 'Coins Spent',
    'earn_coins': 'Earn Coins',
  };
}
