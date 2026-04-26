import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  return PrefsStore();
});

class PrefsStore {
  static const _themeModeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _lastKnownUserNameKey = 'last_known_user_name';
  static const _hasSeenOnboardingKey = 'has_seen_onboarding';

  Future<ThemeMode> get themeMode async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<String> get language async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  Future<bool> get notificationsEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<String?> get lastKnownUserName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastKnownUserNameKey);
  }

  Future<void> setLastKnownUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKnownUserNameKey, name);
  }

  Future<bool> get hasSeenOnboarding async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, value);
  }
}
