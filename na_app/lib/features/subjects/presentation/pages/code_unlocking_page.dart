import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_motion.dart';
import 'package:na_app/features/home/data/home_repository.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';

class CodeUnlockingPage extends ConsumerStatefulWidget {
  final String subjectId;

  const CodeUnlockingPage({super.key, required this.subjectId});

  @override
  ConsumerState<CodeUnlockingPage> createState() => _CodeUnlockingPageState();
}

class _CodeUnlockingPageState extends ConsumerState<CodeUnlockingPage> {
  int _currentStep = 0;
  bool _complete = false;

  static const _steps = [
    _StepData(icon: LucideIcons.search, labelKey: 'subjects.unlocking.step1'),
    _StepData(icon: LucideIcons.link, labelKey: 'subjects.unlocking.step2'),
    _StepData(icon: LucideIcons.download, labelKey: 'subjects.unlocking.step3'),
  ];

  @override
  void initState() {
    super.initState();
    // Defer until after first frame so context has a valid InheritedWidget tree
    // (MediaQuery is not available during initState).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runSteps();
    });
  }

  Future<void> _runSteps() async {
    final shouldReduce = AppMotion.shouldReduceMotion(context);

    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      if (shouldReduce) {
        await Future.delayed(const Duration(milliseconds: 50));
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
      }
      if (!mounted) return;
      setState(() => _currentStep = i + 1);
    }

    await Future.delayed(
      shouldReduce ? const Duration(milliseconds: 100) : const Duration(milliseconds: 400),
    );
    if (!mounted) return;
    setState(() => _complete = true);

    if (!shouldReduce) {
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;

    // Force fresh fetches so both the Today page and the Subjects list are
    // up-to-date before the user can navigate back to them.
    ref.invalidate(todayViewStateProvider);
    try {
      await ref.read(subjectsListProvider.notifier).refresh();
      await ref.read(subjectsListProvider.future);
    } catch (_) {
      // Ignore — the subject detail page will still load via its own provider.
    }
    if (!mounted) return;
    context.go('/subjects/${widget.subjectId}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _complete
                    ? 'subjects.unlocking.successTitle'.tr()
                    : 'subjects.unlocking.loadingTitle'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ...List.generate(_steps.length, (i) {
                final isActive = i <= _currentStep;
                final isDone = i < _currentStep || _complete;
                return _StepRow(
                  step: _steps[i],
                  isActive: isActive,
                  isDone: isDone,
                  isDark: isDark,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final _StepData step;
  final bool isActive;
  final bool isDone;
  final bool isDark;

  const _StepRow({
    required this.step,
    required this.isActive,
    required this.isDone,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isDone
        ? AppColors.success
        : isActive
            ? AppColors.accent
            : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AnimatedContainer(
            duration: AppMotion.medium,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: isDone
                ? const Icon(LucideIcons.check, size: 18, color: AppColors.success)
                : isActive
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fgColor,
                        ),
                      )
                    : Icon(step.icon, size: 18, color: fgColor),
          ),
          const SizedBox(width: 14),
          Text(
            step.labelKey.tr(),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepData {
  final IconData icon;
  final String labelKey;
  const _StepData({required this.icon, required this.labelKey});
}
