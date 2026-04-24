import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final success = await ref.read(authControllerProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go('/today');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your learning journey.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              _buildLabel(context, 'Email'),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: const Icon(LucideIcons.mail, size: 18),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildLabel(context, 'Password'),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(LucideIcons.lock, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/auth/forgot-password'),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Sign in',
                onPressed: _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/auth/register'),
                    child: Text(
                      'Create account',
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
