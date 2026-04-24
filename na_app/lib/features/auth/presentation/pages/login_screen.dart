import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/home/presentation/pages/home_screen.dart';
import 'package:na_app/features/home/presentation/widgets/main_navigation_shell.dart';
import 'package:na_app/core/utils/responsive.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontalPadding = size.width > 600 ? size.width * 0.15 : 24.0;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgSunken,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.chevron_left, size: 24),
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Copy
                      Text(
                        'SIGN IN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.accent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Welcome back.',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pick up right where you left off.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 36),
                      
                      // Form
                      const FieldLabel(label: 'Email'),
                      const SizedBox(height: 6),
                      const NAInput(defaultValue: 'layla.ahmed@na-academy.org'),
                      const SizedBox(height: 14),
                      
                      const FieldLabel(label: 'Password'),
                      const SizedBox(height: 6),
                      const NAInput(defaultValue: '••••••••••', isPassword: true),
                      
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot password?',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Actions
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const MainNavigationShell()),
                              (route) => false,
                            );
                          },
                          child: const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textMuted),
                            children: const [
                              TextSpan(text: 'New here? '),
                              TextSpan(
                                text: 'Create an account',
                                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String label;
  const FieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class NAInput extends StatelessWidget {
  final String defaultValue;
  final bool isPassword;
  const NAInput({super.key, required this.defaultValue, this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        defaultValue,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
