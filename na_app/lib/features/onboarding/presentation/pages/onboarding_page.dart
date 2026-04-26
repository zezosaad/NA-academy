import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:na_app/core/storage/prefs_store.dart';
import 'package:na_app/core/theme/app_colors.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalSlides = 3;

  final _slides = const [
    _OnboardingSlideData(
      icon: LucideIcons.rocket,
      title: 'مرحباً بك في NA-Academy',
      description:
          'منصتك التعليمية المتكاملة. اكتشف عالماً من المعرفة وتفاعل مع موادك الدراسية بأسلوب عصري ومبتكر.',
    ),
    _OnboardingSlideData(
      icon: LucideIcons.messagesSquare,
      title: 'تواصل مع نخبة المعلمين',
      description:
          'لا تتردد في طرح أسئلتك. تواصل مباشرة مع أفضل المعلمين واحصل على التوجيه والدعم الذي تحتاجه.',
    ),
    _OnboardingSlideData(
      icon: LucideIcons.award,
      title: 'اختبر مهاراتك وتفوق',
      description:
          'قم بأداء الاختبارات بسلاسة، وتابع تقدمك الأكاديمي أولاً بأول لتصل إلى أهدافك بثقة ونجاح.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 600),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _finishOnboarding(String route) async {
    await ref.read(prefsStoreProvider).setHasSeenOnboarding(true);
    if (!mounted) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
      body: Directionality(
        textDirection: TextDirection.rtl, // Ensure Arabic layout
        child: Stack(
          children: [
            // Animated Background Blobs
            _buildBackgroundBlobs(isDark, size),

            // Main Content
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                      },
                      itemCount: _totalSlides,
                      itemBuilder: (context, index) {
                        return _buildSlide(
                          context,
                          _slides[index],
                          isDark,
                          index,
                        );
                      },
                    ),
                  ),

                  // Bottom Controls area
                  _buildBottomControls(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundBlobs(bool isDark, Size size) {
    return Stack(
      children: [
        Positioned(
          top: -size.width * 0.2,
          right: -size.width * 0.1,
          child: Pulse(
            infinite: true,
            duration: const Duration(seconds: 4),
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.darkAccent : AppColors.accent)
                    .withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: size.height * 0.1,
          left: -size.width * 0.2,
          child: Pulse(
            infinite: true,
            duration: const Duration(seconds: 5),
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? AppColors.darkSecondary : AppColors.secondary)
                    .withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide(
    BuildContext context,
    _OnboardingSlideData slide,
    bool isDark,
    int index,
  ) {
    final isActive = index == _currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Art/Icon Area
              if (isActive)
                ZoomIn(
                  duration: const Duration(milliseconds: 600),
                  child: _buildArtPiece(slide, isDark, index),
                )
              else
                _buildArtPiece(slide, isDark, index),

              const SizedBox(height: 56),

              // Title
              if (isActive)
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 600),
                  child: _buildTitle(slide.title, isDark),
                )
              else
                _buildTitle(slide.title, isDark),

              const SizedBox(height: 20),

              // Description
              if (isActive)
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  duration: const Duration(milliseconds: 600),
                  child: _buildDescription(slide.description, isDark),
                )
              else
                _buildDescription(slide.description, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtPiece(_OnboardingSlideData slide, bool isDark, int index) {
    return SizedBox(
      height: 240,
      width: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background rotating decorative square
          Spin(
            infinite: true,
            duration: const Duration(seconds: 20),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccentSoft : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? AppColors.darkAccent : AppColors.accent)
                        .withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),

          // Foreground icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBgElevated : AppColors.bgElevated,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                slide.icon,
                size: 56,
                color: isDark ? AppColors.darkAccent : AppColors.accent,
              ),
            ),
          ),

          // Floating decorative elements based on index
          if (index == 0) ...[
            _buildFloatingElement(
              top: 20,
              right: 20,
              color: AppColors.secondary,
              size: 24,
              icon: LucideIcons.sparkles,
              delay: 200,
            ),
            _buildFloatingElement(
              bottom: 30,
              left: 10,
              color: AppColors.success,
              size: 16,
              icon: LucideIcons.star,
              delay: 400,
            ),
          ],
          if (index == 1) ...[
            _buildFloatingElement(
              top: 30,
              left: 15,
              color: AppColors.warning,
              size: 28,
              icon: LucideIcons.messageCircleHeart,
              delay: 300,
            ),
          ],
          if (index == 2) ...[
            _buildFloatingElement(
              bottom: 20,
              right: 10,
              color: AppColors.danger,
              size: 24,
              icon: LucideIcons.medal,
              delay: 250,
            ),
            _buildFloatingElement(
              top: 10,
              left: 30,
              color: AppColors.success,
              size: 20,
              icon: LucideIcons.badgeCheck,
              delay: 500,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingElement({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required Color color,
    required double size,
    required IconData icon,
    required int delay,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: FadeInUp(
        delay: Duration(milliseconds: delay),
        child: Bounce(
          infinite: true,
          duration: const Duration(seconds: 3),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: size, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        height: 1.3,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        height: 1.6,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSlides, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                onTap: () => _goToPage(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (isDark ? AppColors.darkAccent : AppColors.accent)
                        : (isDark
                              ? AppColors.darkBorderStrong
                              : AppColors.borderStrong),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _currentPage < _totalSlides - 1
                ? Column(
                    key: const ValueKey('next_buttons'),
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _goToPage(_currentPage + 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkAccent
                                : AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            textStyle: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('التالي'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _goToPage(_totalSlides - 1),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          textStyle: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('تخطي'),
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey('start_buttons'),
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _finishOnboarding('/auth/register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkAccent
                                : AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            textStyle: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('ابدأ الآن'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _finishOnboarding('/auth/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                          textStyle: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('لدي حساب بالفعل'),
                      ),
                    ],
                  ),
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
