import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_motion.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalSlides = 3;

  final _slides = const [
    _OnboardingSlideData(
      icon: LucideIcons.bookOpen,
      title: 'Unlock subjects',
      description:
          'Enter a code from your teacher to unlock subjects and start learning right away.',
    ),
    _OnboardingSlideData(
      icon: LucideIcons.clipboardCheck,
      title: 'Take exams',
      description:
          'Unlock exams with one-time codes, answer questions with auto-save, and see your results instantly.',
    ),
    _OnboardingSlideData(
      icon: LucideIcons.messageCircle,
      title: 'Chat with tutors',
      description:
          'Message your tutors directly, share images, and get real-time feedback on your progress.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (AppMotion.shouldReduceMotion(context)) {
      _pageController.jumpToPage(page);
    } else {
      _pageController.animateToPage(
        page,
        duration: AppMotion.medium,
        curve: AppMotion.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: AppMotion.shouldReduceMotion(context)
                    ? const NeverScrollableScrollPhysics()
                    : null,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _totalSlides,
                itemBuilder: (context, index) {
                  return _buildSlide(context, _slides[index], isDark);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalSlides, (index) {
                      final isActive = index == _currentPage;
                      return Semantics(
                        label: 'Page ${index + 1}',
                        button: true,
                        child: GestureDetector(
                          onTap: () => _goToPage(index),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: AnimatedContainer(
                                duration: AppMotion.shouldReduceMotion(context) ? Duration.zero : AppMotion.short,
                                width: isActive ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? (isDark ? AppColors.darkAccent : AppColors.accent)
                                      : (isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (_currentPage < _totalSlides - 1) ...[
                    AppButton(
                      label: 'Next',
                      onPressed: () => _goToPage(_currentPage + 1),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Skip',
                      type: AppButtonType.ghost,
                      onPressed: () => _goToPage(_totalSlides - 1),
                    ),
                  ] else ...[
                    AppButton(
                      label: 'Get started',
                      onPressed: () => context.go('/auth/register'),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'I have an account',
                      type: AppButtonType.ghost,
                      onPressed: () => context.go('/auth/login'),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(BuildContext context, _OnboardingSlideData slide, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkAccentSoft : AppColors.accentSoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              slide.icon,
              size: 40,
              color: isDark ? AppColors.darkAccent : AppColors.accent,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: GoogleFonts.fraunces(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
