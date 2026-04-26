import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/core/widgets/max_text_scale.dart';
import 'package:na_app/features/exams/data/exams_repository.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:na_app/features/exams/presentation/controllers/exam_controller.dart';
import 'package:na_app/features/exams/presentation/widgets/exam_timer.dart';
import 'package:na_app/features/exams/presentation/widgets/question_card.dart';
import 'package:animate_do/animate_do.dart';

class TakeExamPage extends ConsumerStatefulWidget {
  final String examId;
  const TakeExamPage({super.key, required this.examId});

  @override
  ConsumerState<TakeExamPage> createState() => _TakeExamPageState();
}

class _TakeExamPageState extends ConsumerState<TakeExamPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Map<String, String> _localAnswers = {};
  bool _isSubmitting = false;
  bool _isStarting = true;
  String? _startError;

  List<ExamQuestion> _questions = [];
  ExamSession? _session;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startExam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _session != null) {
      _refetchSession();
    }
  }

  Future<void> _refetchSession() async {
    try {
      final repo = ref.read(examsRepositoryProvider);
      final result = await repo.getExamAndStart(widget.examId);
      final session = result.session;
      if (session.status == SessionStatus.submitted ||
          session.status == SessionStatus.timedOut) {
        if (mounted) {
          context.go(
            '/exams/${widget.examId}/result',
            extra: {
              'score': ExamScore(sessionId: session.id, score: 0),
              'timedOut': session.status == SessionStatus.timedOut,
            },
          );
        }
        return;
      }
      setState(() {
        _session = session;
        _questions = result.questions;
        for (final entry in session.answers.entries) {
          _localAnswers[entry.key] = entry.value.selectedOption;
        }
      });
    } catch (_) {}
  }

  Future<void> _startExam() async {
    try {
      final repo = ref.read(examsRepositoryProvider);
      final result = await repo.getExamAndStart(widget.examId);
      setState(() {
        _questions = result.questions;
        _session = result.session;
        _isStarting = false;
        for (final entry in result.session.answers.entries) {
          _localAnswers[entry.key] = entry.value.selectedOption;
        }
      });
    } catch (e) {
      setState(() {
        _isStarting = false;
        _startError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaxTextScale(child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isStarting) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.accent),
              const SizedBox(height: 24),
              Text(
                'جاري بدء الاختبار...',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_startError != null) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronRight),
              onPressed: () => context.pop(),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.circleAlert,
                    size: 64,
                    color: isDark ? AppColors.darkDanger : AppColors.danger,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'تعذر بدء الاختبار',
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _startError!,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'رجوع للاختبارات',
                    onPressed: () => context.go('/exams'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_session == null || _questions.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        body: Center(
          child: Text(
            'لا توجد بيانات للاختبار',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final isLastQuestion = _currentIndex == _questions.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldLeave = await _showLeaveDialog(context);
          if (shouldLeave == true && context.mounted) {
            context.go('/exams');
          }
        },
        child: Scaffold(
          backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.x),
              tooltip: 'إغلاق الاختبار',
              onPressed: () async {
                final shouldLeave = await _showLeaveDialog(context);
                if (shouldLeave == true && context.mounted) {
                  context.go('/exams');
                }
              },
            ),
            title: _session!.endsAt.isAfter(DateTime.now())
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: ExamTimer(
                      endsAt: _session!.endsAt, 
                      onExpire: _autoSubmit,
                    ),
                  )
                : null,
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildProgressBar(context, progress, isDark),
              if (_saveError != null)
                FadeInDown(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _saveError!,
                        style: GoogleFonts.cairo(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: QuestionCard(
                    question: question,
                    currentIndex: _currentIndex,
                    totalCount: _questions.length,
                    selectedAnswer: _localAnswers[question.id],
                    onAnswerSelected: _onAnswerSelected,
                  ),
                ),
              ),
              _buildBottomBar(context, isLastQuestion, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'السؤال ${_currentIndex + 1} من ${_questions.length}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.darkAccent : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
              color: isDark ? AppColors.darkAccent : AppColors.accent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    bool isLastQuestion,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  child: AppButton(
                    label: 'السابق',
                    type: AppButtonType.ghost,
                    onPressed: () => setState(() => _currentIndex--),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: AppButton(
                  label: isLastQuestion ? 'تسجيل الإجابات' : 'التالي',
                  type: AppButtonType.primary,
                  onPressed: _isSubmitting
                      ? null
                      : () => isLastQuestion ? _submitExam() : _nextQuestion(),
                  isLoading: _isSubmitting,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAnswerSelected(String optionLabel) {
    final question = _questions[_currentIndex];
    setState(() {
      _localAnswers[question.id] = optionLabel;
      _saveError = null;
    });
    final session = _session;
    if (session != null) {
      ref
          .read(examsRepositoryProvider)
          .saveAnswer(session.id, question.id, optionLabel)
          .catchError((e) {
            if (mounted) {
              setState(() {
                _saveError = 'فشل الحفظ — سيتم إعادة المحاولة عند السؤال التالي';
              });
            }
          });
    }
  }

  Future<void> _nextQuestion() async {
    final question = _questions[_currentIndex];
    if (_localAnswers[question.id] != null) {
      try {
        await ref
            .read(examsRepositoryProvider)
            .saveAnswer(_session!.id, question.id, _localAnswers[question.id]!);
        setState(() {
          _saveError = null;
        });
      } on ApiException catch (e) {
        if (mounted) {
          setState(() {
            _saveError = 'تعذر حفظ الإجابة: ${e.message}';
          });
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() {
            _saveError = 'خطأ في الشبكة — حاول مرة أخرى';
          });
        }
        return;
      }
    }
    setState(() {
      _currentIndex++;
    });
  }

  Future<void> _submitExam() async {
    setState(() => _isSubmitting = true);
    try {
      final answers = _localAnswers.entries
          .map((e) => {'questionId': e.key, 'selectedOption': e.value})
          .toList();
      final repo = ref.read(examsRepositoryProvider);
      final score = await repo.submitSession(_session!.id, answers);
      if (mounted) {
        context.go(
          '/exams/${widget.examId}/result',
          extra: {'score': score, 'timedOut': false},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('فشل تسجيل الإجابات: $e', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.danger,
        ));
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _autoSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      final answers = _localAnswers.entries
          .map((e) => {'questionId': e.key, 'selectedOption': e.value})
          .toList();
      final repo = ref.read(examsRepositoryProvider);
      final score = await repo.submitSession(_session!.id, answers);
      ref.read(examSessionProvider.notifier).markTimedOut();
      if (mounted) {
        context.go(
          '/exams/${widget.examId}/result',
          extra: {'score': score, 'timedOut': true},
        );
      }
    } catch (_) {
      if (mounted) {
        context.go(
          '/exams/${widget.examId}/result',
          extra: {
            'score': ExamScore(sessionId: _session!.id, score: 0),
            'timedOut': true,
          },
        );
      }
    }
  }

  Future<bool?> _showLeaveDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'مغادرة الاختبار؟',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'سيتم حفظ تقدمك، ولكن الوقت سيستمر في النفاذ. هل أنت متأكد؟',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'البقاء',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'مغادرة',
                style: GoogleFonts.cairo(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
