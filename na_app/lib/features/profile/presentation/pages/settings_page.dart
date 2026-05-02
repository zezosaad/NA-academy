import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  static const String _instagramUrl =
      'https://www.instagram.com/na_acadmy1?igsh=MWJqY2I4MW5oZWcyZQ==';
  static const String _telegramUrl = 'https://t.me/na_academy1';
  static const String _youtubeUrl =
      'https://youtube.com/@na_academy?si=pHGwiAF3UQEBzbiQ';
  static final Uri _instagramAppUri = Uri.parse(
    'instagram://user?username=na_acadmy1',
  );
  static final Uri _telegramAppUri = Uri.parse(
    'tg://resolve?domain=na_academy1',
  );
  static final Uri _youtubeAppUri = Uri.parse(
    'youtube://www.youtube.com/@na_academy',
  );

  bool _notificationsEnabled = true;
  bool _localeFollowsSystem = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncNotificationPermission();
    }
  }

  Future<void> _loadPrefs() async {
    final prefsStore = ref.read(prefsStoreProvider);
    final followsSystem = await prefsStore.localeFollowsSystem;
    final notifs = await _syncNotificationPermission(savePreference: false);
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notifs;
      _localeFollowsSystem = followsSystem ?? true;
      _loading = false;
    });
  }

  Future<bool> _syncNotificationPermission({bool savePreference = true}) async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final enabled =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (savePreference) {
      final prefsStore = ref.read(prefsStoreProvider);
      await prefsStore.setNotificationsEnabled(enabled);
    }

    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }

    return enabled;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final selectedMode = ref.watch(themeModeProvider);
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor = isDark
        ? AppColors.darkBorderSubtle
        : AppColors.borderSubtle;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('settings.title'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('settings.title'.tr())),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 120 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'settings.appearance'.tr()),
            const SizedBox(height: 8),
            _buildThemeSelector(
              context,
              isDark,
              bgColor,
              borderColor,
              selectedMode,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'settings.preferences'.tr()),
            const SizedBox(height: 8),
            _buildNotificationsToggle(
              context,
              isDark,
              bgColor,
              borderColor,
              textColor,
              mutedColor,
            ),
            const SizedBox(height: 12),
            _buildLanguageSelector(
              context,
              isDark,
              bgColor,
              borderColor,
              textColor,
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'settings.contact.title'.tr()),
            const SizedBox(height: 8),
            _buildContactLinks(
              context,
              isDark,
              bgColor,
              borderColor,
              textColor,
              mutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactLinks(
    BuildContext context,
    bool isDark,
    Color bgColor,
    Color borderColor,
    Color textColor,
    Color mutedColor,
  ) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            _contactOption(
              context: context,
              icon: LucideIcons.camera,
              label: 'settings.contact.instagramTitle'.tr(),
              description: 'settings.contact.instagramSubtitle'.tr(),
              isDark: isDark,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
              onTap: () => _openDeepLinkWithFallback(
                appUri: _instagramAppUri,
                webUrl: _instagramUrl,
              ),
            ),
            _contactOption(
              context: context,
              icon: LucideIcons.send,
              label: 'settings.contact.telegramTitle'.tr(),
              description: 'settings.contact.telegramSubtitle'.tr(),
              isDark: isDark,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
              onTap: () => _openDeepLinkWithFallback(
                appUri: _telegramAppUri,
                webUrl: _telegramUrl,
              ),
            ),
            _contactOption(
              context: context,
              icon: LucideIcons.play,
              label: 'settings.contact.youtubeTitle'.tr(),
              description: 'settings.contact.youtubeSubtitle'.tr(),
              isDark: isDark,
              borderColor: borderColor,
              textColor: textColor,
              mutedColor: mutedColor,
              onTap: () => _openDeepLinkWithFallback(
                appUri: _youtubeAppUri,
                webUrl: _youtubeUrl,
              ),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
    required Future<void> Function() onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: textColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.externalLink, size: 16, color: mutedColor),
          ],
        ),
      ),
    );
  }

  Future<void> _openDeepLinkWithFallback({
    required Uri appUri,
    required String webUrl,
  }) async {
    final webUri = Uri.tryParse(webUrl);
    if (webUri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings.contact.openFailed'.tr())),
      );
      return;
    }

    var openedApp = false;
    try {
      final canOpenApp = await canLaunchUrl(appUri);
      if (canOpenApp) {
        openedApp = await launchUrl(
          appUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } on PlatformException {
      openedApp = false;
    }
    if (openedApp) return;

    bool openedWeb;
    try {
      openedWeb = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      openedWeb = false;
    }
    if (!openedWeb && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settings.contact.openFailed'.tr())),
      );
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    bool isDark,
    Color bgColor,
    Color borderColor,
    ThemeMode selectedMode,
  ) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            _themeOption(
              context: context,
              icon: LucideIcons.monitor,
              label: 'settings.theme.system'.tr(),
              description: 'settings.theme.systemDescription'.tr(),
              value: ThemeMode.system,
              isDark: isDark,
              borderColor: borderColor,
              selectedMode: selectedMode,
            ),
            _themeOption(
              context: context,
              icon: LucideIcons.sun,
              label: 'settings.theme.light'.tr(),
              description: 'settings.theme.lightDescription'.tr(),
              value: ThemeMode.light,
              isDark: isDark,
              borderColor: borderColor,
              selectedMode: selectedMode,
            ),
            _themeOption(
              context: context,
              icon: LucideIcons.moon,
              label: 'settings.theme.dark'.tr(),
              description: 'settings.theme.darkDescription'.tr(),
              value: ThemeMode.dark,
              isDark: isDark,
              borderColor: borderColor,
              selectedMode: selectedMode,
              isLast: true,
            ),
          ],
        ),
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
    required ThemeMode selectedMode,
    bool isLast = false,
  }) {
    final isSelected = selectedMode == value;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return InkWell(
      onTap: () => _onThemeChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Semantics(
          label: 'settings.theme.semanticLabel'.tr(
            namedArgs: {'label': label, 'description': description},
          ),
          selected: isSelected,
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? accentColor
                    : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    await ref.read(themeModeProvider.notifier).setMode(mode);
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
      child: Column(
        children: [
          SwitchListTile(
            value: _notificationsEnabled,
            onChanged: (enabled) async {
              final prefsStore = ref.read(prefsStoreProvider);
              if (enabled) {
                await FirebaseMessaging.instance.requestPermission(
                  alert: true,
                  badge: true,
                  sound: true,
                );
                await _syncNotificationPermission();
              } else {
                final settings = await FirebaseMessaging.instance
                    .getNotificationSettings();
                final osStillEnabled =
                    settings.authorizationStatus ==
                        AuthorizationStatus.authorized ||
                    settings.authorizationStatus ==
                        AuthorizationStatus.provisional;

                if (osStillEnabled && mounted) {
                  final openSettings = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: const Text('Notifications'),
                        content: Text(
                          'notifications.permission_denied_explainer'.tr(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Open settings'),
                          ),
                        ],
                      );
                    },
                  );

                  if (openSettings == true) {
                    await openAppSettings();
                  }
                }

                await prefsStore.setNotificationsEnabled(false);
                if (mounted) {
                  setState(() => _notificationsEnabled = false);
                }
              }
            },
            title: Text(
              'settings.notifications.title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 15),
            ),
            subtitle: Text(
              _notificationsEnabled
                  ? 'settings.notifications.enabled'.tr()
                  : 'settings.notifications.disabled'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
            secondary: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(LucideIcons.bell, size: 16, color: textColor),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          InkWell(
            onTap: () => context.push('/notifications'),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'notifications.inbox_title'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: textColor),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: mutedColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    bool isDark,
    Color bgColor,
    Color borderColor,
    Color textColor,
  ) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
            _languageOption(
              context: context,
              icon: LucideIcons.monitor,
              label: 'settings.language.system'.tr(),
              description: 'settings.language.systemDescription'.tr(),
              isDark: isDark,
              borderColor: borderColor,
              isSelected: _localeFollowsSystem,
              onTap: () => _selectLanguageSystem(),
            ),
            _languageOption(
              context: context,
              icon: LucideIcons.languages,
              label: 'settings.language.english'.tr(),
              description: 'settings.language.englishDescription'.tr(),
              isDark: isDark,
              borderColor: borderColor,
              isSelected:
                  !_localeFollowsSystem && context.locale == const Locale('en'),
              onTap: () => _selectLanguage(const Locale('en')),
            ),
            _languageOption(
              context: context,
              icon: LucideIcons.languages,
              label: 'settings.language.arabic'.tr(),
              description: 'settings.language.arabicDescription'.tr(),
              isDark: isDark,
              borderColor: borderColor,
              isSelected:
                  !_localeFollowsSystem && context.locale == const Locale('ar'),
              onTap: () => _selectLanguage(const Locale('ar')),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required bool isDark,
    required Color borderColor,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Semantics(
          label: 'settings.language.semanticLabel'.tr(
            namedArgs: {'label': label, 'description': description},
          ),
          selected: isSelected,
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? accentColor
                    : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 15),
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  Future<void> _selectLanguageSystem() async {
    final prefsStore = ref.read(prefsStoreProvider);
    await prefsStore.setLocaleFollowsSystem(true);
    if (!mounted) return;
    setState(() => _localeFollowsSystem = true);
    await context.resetLocale();
  }

  Future<void> _selectLanguage(Locale locale) async {
    final prefsStore = ref.read(prefsStoreProvider);
    await prefsStore.setLocaleFollowsSystem(false);
    if (!mounted) return;
    setState(() => _localeFollowsSystem = false);
    await context.setLocale(locale);
  }
}
