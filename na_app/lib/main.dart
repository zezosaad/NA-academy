import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/theme/app_theme.dart';
import 'package:na_app/core/router/app_router.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final prefs = PrefsStore();
  final initialThemeMode = await prefs.themeMode;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      startLocale: const Locale('ar'),
      fallbackLocale: const Locale('ar'),
      useOnlyLangCode: true,
      child: ProviderScope(
        overrides: [
          prefsStoreProvider.overrideWithValue(prefs),
          themeModeProvider.overrideWith(
            (ref) => ThemeModeController(prefs, initialThemeMode),
          ),
        ],
        child: const NAApp(),
      ),
    ),
  );
}

class NAApp extends ConsumerStatefulWidget {
  const NAApp({super.key});

  @override
  ConsumerState<NAApp> createState() => _NAAppState();
}

class _NAAppState extends ConsumerState<NAApp> {
  @override
  void initState() {
    super.initState();
    _listenSessionExpiry();
  }

  void _listenSessionExpiry() {
    sessionExpiredStream.listen((_) {
      ref.invalidate(authControllerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<AsyncValue>(authControllerProvider, (prev, next) {
      if (prev?.value != null && next.value == null) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Text('session.expired'.tr()),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });

    return MaterialApp.router(
      title: 'NA-Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
    );
  }
}
