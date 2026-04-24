import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    _navigate();
  }

  void _navigate() {
    _navigated = true;
    final authState = ref.read(authControllerProvider);
    if (authState.valueOrNull != null) {
      context.go('/today');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(authControllerProvider, (prev, next) {
      if (!next.isLoading && !_navigated && mounted) {
        _navigate();
      }
    });

    return Scaffold(
      body: Container(
        color: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBgSurface : AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'NA',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 32,
                          color: AppColors.accent,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
