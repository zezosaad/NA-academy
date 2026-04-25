import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/storage/prefs_store.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  ThemeMode _selectedTheme = ThemeMode.system;
  bool _notificationsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefsStore = ref.read(prefsStoreProvider);
    final theme = await prefsStore.themeMode;
    final notifs = await prefsStore.notificationsEnabled;
    if (!mounted) return;
    setState(() {
      _selectedTheme = theme;
      _notificationsEnabled = notifs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Appearance'),
            const SizedBox(height: 8),
            _buildThemeSelector(context, isDark, bgColor, borderColor),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Preferences'),
            const SizedBox(height: 8),
            _buildNotificationsToggle(
                context, isDark, bgColor, borderColor, textColor, mutedColor),
            const SizedBox(height: 12),
            _buildLanguageRow(
                context, isDark, bgColor, borderColor, textColor, mutedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    bool isDark,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _themeOption(
            context: context,
            icon: LucideIcons.monitor,
            label: 'System',
            description: 'Follow device settings',
            value: ThemeMode.system,
            isDark: isDark,
            borderColor: borderColor,
          ),
          _themeOption(
            context: context,
            icon: LucideIcons.sun,
            label: 'Light',
            description: 'Always use light theme',
            value: ThemeMode.light,
            isDark: isDark,
            borderColor: borderColor,
          ),
          _themeOption(
            context: context,
            icon: LucideIcons.moon,
            label: 'Dark',
            description: 'Always use dark theme',
            value: ThemeMode.dark,
            isDark: isDark,
            borderColor: borderColor,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required ThemeMode value,
    required bool isDark,
    required Color borderColor,
    bool isLast = false,
  }) {
    final isSelected = _selectedTheme == value;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return InkWell(
      onTap: () => _onThemeChanged(value),
      borderRadius: BorderRadius.vertical(
        top: value == ThemeMode.system ? const Radius.circular(18) : Radius.zero,
        bottom: isLast ? const Radius.circular(18) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Semantics(
          label: '$label theme: $description',
          selected: isSelected,
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected ? accentColor : (isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 15),
                    ),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(LucideIcons.check, size: 18, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onThemeChanged(ThemeMode mode) async {
    setState(() => _selectedTheme = mode);
    final prefsStore = ref.read(prefsStoreProvider);
    await prefsStore.setThemeMode(mode);
  }

  Widget _buildNotificationsToggle(
    BuildContext context,
    bool isDark,
    Color bgColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: SwitchListTile(
        value: _notificationsEnabled,
        onChanged: (enabled) async {
          setState(() => _notificationsEnabled = enabled);
          final prefsStore = ref.read(prefsStoreProvider);
          await prefsStore.setNotificationsEnabled(enabled);
        },
        title: Text(
          'Notifications',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontSize: 15),
        ),
        subtitle: Text(
          _notificationsEnabled
              ? 'Daily reminders are enabled'
              : 'Daily reminders are disabled',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: mutedColor,
              ),
        ),
        secondary: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.bell,
            size: 16,
            color: textColor,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildLanguageRow(
    BuildContext context,
    bool isDark,
    Color bgColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.globe,
            size: 16,
            color: textColor,
          ),
        ),
        title: Text(
          'Language',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontSize: 15),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'English',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                  ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: mutedColor,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Additional languages coming soon.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
