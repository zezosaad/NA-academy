import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/theme/app_theme.dart';
import 'package:na_app/core/router/app_router.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NAApp()));
}

class NAApp extends ConsumerStatefulWidget {
  const NAApp({super.key});

  @override
  ConsumerState<NAApp> createState() => _NAAppState();
}

class _NAAppState extends ConsumerState<NAApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _themeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _listenSessionExpiry();
  }

  Future<void> _loadTheme() async {
    final prefsStore = ref.read(prefsStoreProvider);
    final mode = await prefsStore.themeMode;
    if (mounted) {
      setState(() {
        _themeMode = mode;
        _themeLoaded = true;
      });
    }
  }

  void _listenSessionExpiry() {
    sessionExpiredStream.listen((_) {
      ref.invalidate(authControllerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    ref.listen<AsyncValue>(authControllerProvider, (prev, next) {
      if (prev?.value != null && next.value == null) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Session ended — please sign in again'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });

    if (!_themeLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp.router(
      title: 'NA-Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      routerConfig: router,
    );
  }
}
