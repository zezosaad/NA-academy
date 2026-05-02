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

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  bool _navigated = false;

  // Logo: drops from the top with a bounce
  late final AnimationController _logoController;
  late final Animation<double> _logoSlide;
  late final Animation<double> _logoFade;

  // Welcome text: fades + slides up after the logo lands
  late final AnimationController _textController;
  late final Animation<double> _textFade;
  late final Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();

    // ── Logo animation (drop + bounce) ────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.bounceOut),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // ── Text animation (fade-in + slide up) ───────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Start logo, then trigger text 700 ms later
    _logoController.forward().then((_) {
      if (mounted) _textController.forward();
    });

    _startSplash();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startSplash() async {
    // Give the animations time to play (≥ 1.5 s total)
    await Future.delayed(const Duration(milliseconds: 1600));
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        color: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Animated Logo (drop + bounce) ─────────────────────
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _logoSlide.value * screenHeight * 0.45),
                    child: Opacity(
                      opacity: _logoFade.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 48,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Animated welcome text ─────────────────────────────
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      'مرحبًا بكم في',
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary)
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'NA Academy',
                      style: GoogleFonts.cairo(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── Loading indicator ─────────────────────────────────
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
