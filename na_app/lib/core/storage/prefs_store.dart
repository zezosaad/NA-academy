import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  return PrefsStore();
});

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController(ref.watch(prefsStoreProvider), ThemeMode.light)
      .._loadFromStore();
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._store, ThemeMode initial) : super(initial);

  final PrefsStore _store;

  Future<void> _loadFromStore() async {
    final stored = await _store.themeMode;
    if (mounted && stored != state) state = stored;
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _store.setThemeMode(mode);
  }
}

class PrefsStore {
  static const _themeModeKey = 'theme_mode';
  static const _localeFollowsSystemKey = 'locale_follows_system';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _lastKnownUserNameKey = 'last_known_user_name';
  static const _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const _savedLessonIdsKey = 'saved_lesson_ids';

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

  Future<bool> get localeFollowsSystem async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_localeFollowsSystemKey) ?? true;
  }

  Future<void> setLocaleFollowsSystem(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_localeFollowsSystemKey, value);
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

  Future<List<String>> get savedLessonIds async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_savedLessonIdsKey) ?? const <String>[];
    return ids.where((id) => id.isNotEmpty).toSet().toList();
  }

  Future<bool> isLessonSaved(String lessonId) async {
    final ids = await savedLessonIds;
    return ids.contains(lessonId);
  }

  Future<bool> toggleSavedLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_savedLessonIdsKey) ?? const <String>[])
        .where((id) => id.isNotEmpty)
        .toList();

    final exists = ids.contains(lessonId);
    if (exists) {
      ids.removeWhere((id) => id == lessonId);
    } else {
      ids.add(lessonId);
    }

    await prefs.setStringList(_savedLessonIdsKey, ids.toSet().toList());
    return !exists;
  }

  Future<void> removeSavedLesson(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_savedLessonIdsKey) ?? const <String>[])
        .where((id) => id.isNotEmpty && id != lessonId)
        .toSet()
        .toList();
    await prefs.setStringList(_savedLessonIdsKey, ids);
  }
}
