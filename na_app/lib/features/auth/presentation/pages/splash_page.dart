import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || _navigated) return;

    final authState = ref.read(authControllerProvider);
    if (authState.isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted || _navigated) return false;
        return ref.read(authControllerProvider).isLoading;
      });
    }
    if (!mounted || _navigated) return;
    await _navigate(ref.read(authControllerProvider).valueOrNull);
  }

  Future<void> _navigate(Object? user) async {
    if (_navigated) return;
    _navigated = true;
    if (user != null) {
      context.go('/today');
    } else {
      final hasSeenOnboarding = await ref
          .read(prefsStoreProvider)
          .hasSeenOnboarding;
      if (!mounted) return;
      context.go(hasSeenOnboarding ? '/auth/login' : '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(authControllerProvider, (prev, next) {
      if (!next.isLoading && !_navigated && mounted) {
        unawaited(_navigate(next.valueOrNull));
      }
    });

    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return Scaffold(
      body: Container(
        color: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo ──────────────────────────────────────────────
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              // ── App name ──────────────────────────────────────────
              Text(
                'NA Academy',
                style: GoogleFonts.cairo(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              // ── Loading indicator ─────────────────────────────────
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
