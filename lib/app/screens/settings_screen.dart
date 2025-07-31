import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Sozlamalar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, _) {
          if (!settings.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance section
                _buildSectionCard(
                  context: context,
                  title: 'Tashqi ko\'rinish',
                  icon: Icons.palette_outlined,
                  children: [
                    _buildThemeSelector(context, settings),
                    const SizedBox(height: 8),
                    _buildLanguageSelector(context, settings),
                  ],
                ),

                const SizedBox(height: 16),

                // Notifications section
                _buildSectionCard(
                  context: context,
                  title: 'Bildirishnomalar',
                  icon: Icons.notifications_outlined,
                  children: [
                    _buildNotificationToggle(context, settings),
                  ],
                ),

                const SizedBox(height: 16),

                // Additional settings section
                _buildSectionCard(
                  context: context,
                  title: 'Boshqalar',
                  icon: Icons.settings_outlined,
                  children: [
                    _buildResetButton(context, settings),
                    const SizedBox(height: 8),
                    _buildAboutTile(context),
                  ],
                ),

                const SizedBox(height: 32),

                // App info
                _buildAppInfo(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsService settings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Icon(
          _getThemeIcon(settings.themeMode),
          color: colorScheme.primary,
        ),
        title: Text(
          'Mavzu',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _getThemeText(settings.themeMode),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: PopupMenuButton<ThemeMode>(
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          onSelected: (ThemeMode mode) {
            settings.setThemeMode(mode);
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(Icons.brightness_auto),
                  SizedBox(width: 12),
                  Text('Tizim bo\'yicha'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(Icons.light_mode),
                  SizedBox(width: 12),
                  Text('Yorug\''),
                ],
              ),
            ),
            const PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(Icons.dark_mode),
                  SizedBox(width: 12),
                  Text('Tungi'),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildLanguageSelector(
      BuildContext context, SettingsService settings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.language,
          color: colorScheme.primary,
        ),
        title: Text(
          'Ilova tili',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _getLanguageName(settings.locale),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: PopupMenuButton<Locale>(
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          onSelected: (Locale locale) {
            settings.setLocale(locale);
          },
          itemBuilder: (BuildContext context) => const [
            PopupMenuItem(
              value: Locale('uz', 'UZ'),
              child: Row(
                children: [
                  Text('🇺🇿'),
                  SizedBox(width: 12),
                  Text('O\'zbekcha'),
                ],
              ),
            ),
            PopupMenuItem(
              value: Locale('ru', 'RU'),
              child: Row(
                children: [
                  Text('🇷🇺'),
                  SizedBox(width: 12),
                  Text('Русский'),
                ],
              ),
            ),
            PopupMenuItem(
              value: Locale('en', 'US'),
              child: Row(
                children: [
                  Text('🇺🇸'),
                  SizedBox(width: 12),
                  Text('English'),
                ],
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildNotificationToggle(
      BuildContext context, SettingsService settings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(
          settings.notificationsEnabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: colorScheme.primary,
        ),
        title: Text(
          'Bildirishnomalar',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          settings.notificationsEnabled
              ? 'Bildirishnomalar yoqilgan'
              : 'Bildirishnomalar o\'chirilgan',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        value: settings.notificationsEnabled,
        onChanged: (bool value) {
          settings.setNotificationsEnabled(value);
        },
        activeColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, SettingsService settings) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.restore,
          color: colorScheme.error,
        ),
        title: Text(
          'Sozlamalarni tiklash',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.error,
          ),
        ),
        subtitle: Text(
          'Barcha sozlamalarni standart holatga qaytarish',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        onTap: () => _showResetDialog(context, settings),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.info_outline,
          color: colorScheme.primary,
        ),
        title: Text(
          'Ilova haqida',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Versiya va qo\'shimcha ma\'lumotlar',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
        onTap: () => _showAboutDialog(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.settings,
            size: 48,
            color: colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Mening Ilovam',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Versiya 1.0.0',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sozlamalarni tiklash'),
          content: const Text(
            'Barcha sozlamalar standart holatga qaytariladi. Davom etasizmi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
            FilledButton(
              onPressed: () async {
                await settings.resetAllSettings();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sozlamalar muvaffaqiyatli tiklandi'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Tiklash'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Mening Ilovam',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.settings, size: 64),
      children: const [
        Text('Bu ilova Flutter yordamida yaratilgan.'),
        SizedBox(height: 16),
        Text('Barcha huquqlar himoyalangan © 2025'),
      ],
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Yorug\' mavzu';
      case ThemeMode.dark:
        return 'Tungi mavzu';
      case ThemeMode.system:
        return 'Tizim bo\'yicha';
    }
  }

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'uz':
        return 'O\'zbekcha';
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return 'O\'zbekcha';
    }
  }
}
