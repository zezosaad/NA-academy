import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/auth/presentation/pages/login_screen.dart';
import 'package:na_app/core/utils/responsive.dart';

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
      title: 'A calm place\nto study, ask,\nand grow.',
      body: 'NA-Academy brings your lessons, exams, and tutors into one focused space.',
    ),
    OnboardingData(
      kicker: 'Learn',
      title: 'Subjects that\nmove with you.',
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
      padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: isShort ? 16 : 28),
          
          // Art Area
          Expanded(
            flex: isShort ? 2 : 3,
            child: _buildArtArea(),
          ),
          SizedBox(height: isShort ? 16 : 28),
          
          // Copy Area
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
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            'N',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.bgCanvas,
              fontSize: 18,
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
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(31, 28, 22, 0.04),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
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
          SizedBox(height: isShort ? 6 : 10),
          FadeInUp(
            key: ValueKey('title-$_currentSlide'),
            duration: const Duration(milliseconds: 500),
            child: Text(
              _slides[_currentSlide].title,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: isShort ? 24 : 32,
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
        // Dots
        Row(
          children: List.generate(_slides.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              width: index == _currentSlide ? 32 : 16,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: index == _currentSlide ? AppColors.accent : AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        
        // Actions
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_currentSlide < _slides.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
            ),
            child: Text(_currentSlide < _slides.length - 1 ? 'Continue' : 'Get started'),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'I have an account',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
        final baseSize = size * 0.6;

        if (index == 0) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: baseSize,
                height: baseSize,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  'NA',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.accentDeep,
                    fontSize: baseSize * 0.3,
                  ),
                ),
              ),
              Positioned(
                right: baseSize * 0.2,
                top: baseSize * 0.3,
                child: Container(
                  width: baseSize * 0.17,
                  height: baseSize * 0.17,
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondary),
                  ),
                ),
              ),
              Positioned(
                left: baseSize * 0.2,
                bottom: baseSize * 0.2,
                child: Container(
                  width: baseSize * 0.25,
                  height: baseSize * 0.25,
                  decoration: BoxDecoration(
                    color: AppColors.bgSunken,
                    borderRadius: BorderRadius.circular(baseSize * 0.06),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                ),
              ),
            ],
          );
        }
        return Icon(
          index == 1 ? Icons.school : Icons.chat_bubble,
          size: baseSize,
          color: AppColors.accentSoft,
        );
      },
    );
  }
}

class OnboardingData {
  final String kicker;
  final String title;
  final String body;

  OnboardingData({required this.kicker, required this.title, required this.body});
}
