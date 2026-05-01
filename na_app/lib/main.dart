import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:na_app/core/theme/app_theme.dart';
import 'package:na_app/core/router/app_router.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/notifications/firebase_bootstrap.dart';
import 'package:na_app/core/notifications/local_notifications.dart';
import 'package:na_app/core/notifications/push_message_handler.dart';
import 'package:na_app/features/notifications/presentation/widgets/foreground_notification_banner.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeNotifications();
  await LocalNotificationsService.initialize();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
    _setupFcmListeners();
  }

  void _listenSessionExpiry() {
    sessionExpiredStream.listen((_) {
      ref.invalidate(authControllerProvider);
    });
  }

  void _setupFcmListeners() {
    FirebaseMessaging.onMessage.listen((message) async {
      await handleForegroundMessage(message);
      if (!mounted) return;
      ForegroundNotificationBanner.show(
        context,
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        onTap: () {
          final target = extractDeepLinkTarget(message);
          final router = ref.read(appRouterProvider);
          if (target != null) {
            _openTarget(router, target, message);
            return;
          }

          final notifId = extractNotificationId(message);
          if (notifId != null) {
            router.push('/notifications/$notifId');
          }
        },
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await handleMessageOpenedApp(message);
      final target = extractDeepLinkTarget(message);
      if (target != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final router = ref.read(appRouterProvider);
          _openTarget(router, target, message);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final router = ref.read(appRouterProvider);
          final notifId = extractNotificationId(message);
          if (notifId != null) {
            router.push('/notifications/$notifId');
          }
        });
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message != null) {
        await handleInitialMessage(message);
        final target = extractDeepLinkTarget(message);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final router = ref.read(appRouterProvider);
          if (target != null) {
            _openTarget(router, target, message);
          } else {
            final notifId = extractNotificationId(message);
            if (notifId != null) {
              router.push('/notifications/$notifId');
            }
          }
        });
      }
    });
  }

  void _openTarget(GoRouter router, String target, RemoteMessage message) {
    if (target.startsWith('http://') || target.startsWith('https://')) {
      final uri = Uri.tryParse(target);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return;
      }
      unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
      return;
    }

    router.push(target);
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
