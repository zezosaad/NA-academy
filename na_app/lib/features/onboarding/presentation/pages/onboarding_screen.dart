import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/auth/presentation/pages/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentSlide = 0;
  final PageController _pageController = PageController();

  final List<OnboardingData> _slides = [
    OnboardingData(
      kicker: 'Welcome',
      title: 'Your study\nspace,\nreimagined.',
      body: 'NA-Academy brings your lessons, exams, and tutors into one focused, modern platform.',
    ),
    OnboardingData(
      kicker: 'Learn',
      title: 'Subjects that\nkeep pace\nwith you.',
      body: 'Bite-sized lessons, progress that sticks, and quick checks to prove you got it.',
    ),
    OnboardingData(
      kicker: 'Ask',
      title: 'A tutor in\nyour pocket.',
      body: 'Message your teacher, share a photo of a problem, and get unstuck in minutes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isShort = size.height < 600;
    final horizontalPadding = size.width > 600 ? size.width * 0.1 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 900) {
              return _buildLargeScreenLayout(context, horizontalPadding);
            }
            return _buildMobileLayout(context, horizontalPadding, isShort);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, double horizontalPadding, bool isShort) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: isShort ? 20 : 32),
          Expanded(
            flex: isShort ? 2 : 3,
            child: _buildArtArea(),
          ),
          SizedBox(height: isShort ? 20 : 32),
          Expanded(
            flex: 2,
            child: _buildCopyArea(context, isShort),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout(BuildContext context, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 48),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildArtArea(),
                  ),
                ),
                const SizedBox(width: 60),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCopyArea(context, false),
                      const SizedBox(height: 40),
                      _buildFooter(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Text(
            'N',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Sora',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'NA·Academy',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 17),
        ),
      ],
    );
  }

  Widget _buildArtArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentSlide = index);
          },
          itemCount: _slides.length,
          itemBuilder: (context, index) {
            return Center(
              child: OnboardingArt(index: index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCopyArea(BuildContext context, bool isShort) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeInUp(
            key: ValueKey('kicker-$_currentSlide'),
            duration: const Duration(milliseconds: 400),
            child: Text(
              _slides[_currentSlide].kicker.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontSize: isShort ? 10 : 11,
              ),
            ),
          ),
          SizedBox(height: isShort ? 8 : 12),
          FadeInUp(
            key: ValueKey('title-$_currentSlide'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              _slides[_currentSlide].title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: isShort ? 26 : 34,
              ),
            ),
          ),
          SizedBox(height: isShort ? 10 : 14),
          FadeInUp(
            key: ValueKey('body-$_currentSlide'),
            duration: const Duration(milliseconds: 600),
            child: Text(
              _slides[_currentSlide].body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isShort ? 14 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(_slides.length, (index) {
            final isActive = index == _currentSlide;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              height: 5,
              width: isActive ? 36 : 12,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_currentSlide < _slides.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: Text(
              _currentSlide < _slides.length - 1 ? 'Continue' : 'Get started',
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {},
            child: const Text('I have an account'),
          ),
        ),
      ],
    );
  }
}

class OnboardingArt extends StatelessWidget {
  final int index;
  const OnboardingArt({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final baseSize = size * 0.55;

        if (index == 0) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: baseSize * 0.7,
                height: baseSize * 0.7,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(baseSize * 0.15),
                ),
                alignment: Alignment.center,
                child: Text(
                  'NA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: baseSize * 0.22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Sora',
                  ),
                ),
              ),
              Positioned(
                right: baseSize * 0.15,
                top: baseSize * 0.2,
                child: Container(
                  width: baseSize * 0.18,
                  height: baseSize * 0.18,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(baseSize * 0.05),
                  ),
                ),
              ),
              Positioned(
                left: baseSize * 0.12,
                bottom: baseSize * 0.22,
                child: Container(
                  width: baseSize * 0.14,
                  height: baseSize * 0.14,
                  decoration: BoxDecoration(
                    color: AppColors.accentGlow.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: baseSize * 0.25,
                bottom: baseSize * 0.15,
                child: Container(
                  width: baseSize * 0.22,
                  height: baseSize * 0.22,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(baseSize * 0.06),
                  ),
                ),
              ),
            ],
          );
        }

        if (index == 1) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: baseSize * 0.55,
                height: baseSize * 0.55,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(baseSize * 0.12),
                ),
                child: CustomPaint(
                  size: Size(baseSize * 0.55, baseSize * 0.55),
                  painter: _BookPainter(),
                ),
              ),
              Positioned(
                right: baseSize * 0.18,
                top: baseSize * 0.18,
                child: Container(
                  width: baseSize * 0.12,
                  height: baseSize * 0.12,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: baseSize * 0.2,
                bottom: baseSize * 0.15,
                child: Container(
                  width: baseSize * 0.16,
                  height: baseSize * 0.16,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(baseSize * 0.04),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: baseSize * 0.5,
              height: baseSize * 0.5,
              decoration: BoxDecoration(
                color: AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(baseSize * 0.25),
              ),
              child: CustomPaint(
                size: Size(baseSize * 0.5, baseSize * 0.5),
                painter: _ChatPainter(),
              ),
            ),
            Positioned(
              left: baseSize * 0.2,
              top: baseSize * 0.22,
              child: Container(
                width: baseSize * 0.15,
                height: baseSize * 0.15,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(baseSize * 0.04),
                ),
              ),
            ),
            Positioned(
              right: baseSize * 0.15,
              bottom: baseSize * 0.2,
              child: Container(
                width: baseSize * 0.1,
                height: baseSize * 0.1,
                decoration: const BoxDecoration(
                  color: AppColors.accentGlow,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final bookWidth = size.width * 0.5;
    final bookHeight = size.height * 0.6;

    final spine = Path()
      ..moveTo(centerX, centerY - bookHeight / 2)
      ..lineTo(centerX, centerY + bookHeight / 2);
    canvas.drawPath(spine, paint);

    final leftPage = Path()
      ..moveTo(centerX, centerY - bookHeight / 2)
      ..quadraticBezierTo(
        centerX - bookWidth * 0.3, centerY - bookHeight / 2 - 8,
        centerX - bookWidth, centerY - bookHeight / 2 + 4,
      )
      ..lineTo(centerX - bookWidth, centerY + bookHeight / 2 - 4)
      ..quadraticBezierTo(
        centerX - bookWidth * 0.3, centerY + bookHeight / 2 + 8,
        centerX, centerY + bookHeight / 2,
      );
    canvas.drawPath(leftPage, paint);

    final rightPage = Path()
      ..moveTo(centerX, centerY - bookHeight / 2)
      ..quadraticBezierTo(
        centerX + bookWidth * 0.3, centerY - bookHeight / 2 - 8,
        centerX + bookWidth, centerY - bookHeight / 2 + 4,
      )
      ..lineTo(centerX + bookWidth, centerY + bookHeight / 2 - 4)
      ..quadraticBezierTo(
        centerX + bookWidth * 0.3, centerY + bookHeight / 2 + 8,
        centerX, centerY + bookHeight / 2,
      );
    canvas.drawPath(rightPage, paint);

    final linePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final y = centerY - bookHeight / 4 + (i * bookHeight / 6);
      canvas.drawLine(
        Offset(centerX - bookWidth * 0.7, y),
        Offset(centerX - bookWidth * 0.2, y),
        linePaint,
      );
      canvas.drawLine(
        Offset(centerX + bookWidth * 0.2, y),
        Offset(centerX + bookWidth * 0.7, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final bubble1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15, size.height * 0.2,
        size.width * 0.55, size.height * 0.25,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(bubble1, paint);

    final bubble2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.3, size.height * 0.5,
        size.width * 0.55, size.height * 0.25,
      ),
      const Radius.circular(12),
    );
    canvas.drawRRect(bubble2, paint);

    final dotPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.32 + i * size.width * 0.08, size.height * 0.32),
        3,
        dotPaint,
      );
    }

    final dotPaint2 = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.47 + i * size.width * 0.08, size.height * 0.62),
        3,
        dotPaint2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingData {
  final String kicker;
  final String title;
  final String body;

  OnboardingData({required this.kicker, required this.title, required this.body});
}
