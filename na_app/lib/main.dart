import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_theme.dart';
import 'package:na_app/features/onboarding/presentation/pages/onboarding_screen.dart';

void main() {
  runApp(const NAApp());
}

class NAApp extends StatelessWidget {
  const NAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NA-Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}
