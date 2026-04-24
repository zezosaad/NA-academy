import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/features/exams/data/exams_repository.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:na_app/features/exams/presentation/controllers/exam_controller.dart';
import 'package:na_app/features/exams/presentation/widgets/exam_timer.dart';
import 'package:na_app/features/exams/presentation/widgets/question_card.dart';

class TakeExamPage extends ConsumerStatefulWidget {
  final String examId;
  const TakeExamPage({super.key, required this.examId});

  @override
  ConsumerState<TakeExamPage> createState() => _TakeExamPageState();
}

class _TakeExamPageState extends ConsumerState<TakeExamPage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Map<String, String> _localAnswers = {};
  bool _isSubmitting = false;
  bool _isStarting = true;
  String? _startError;

  List<ExamQuestion> _questions = [];
  ExamSession? _session;

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
      if (session.status == SessionStatus.submitted || session.status == SessionStatus.timedOut) {
        if (mounted) {
          final repo2 = ref.read(examsRepositoryProvider);
          late ExamScore score;
          try {
            final answers = _localAnswers.entries.map((e) => {'questionId': e.key, 'selectedOption': e.value}).toList();
            score = await repo2.submitSession(session.id, answers);
          } catch (_) {
            score = ExamScore(sessionId: session.id, score: 0);
          }
          context.go('/exams/${widget.examId}/result', extra: {'score': score, 'timedOut': session.status == SessionStatus.timedOut});
        }
        return;
      }
      setState(() {
        _session = session;
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
      ref.read(examSessionProvider.notifier).startSession(widget.examId);
    } catch (e) {
      setState(() {
        _isStarting = false;
        _startError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isStarting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Starting exam...')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_startError != null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => context.pop())),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.circleAlert, size: 48, color: isDark ? AppColors.darkDanger : AppColors.danger),
              const SizedBox(height: 16),
              Text('Could not start exam', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(_startError!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              AppButton(label: 'Go back', onPressed: () => context.go('/exams')),
            ],
          ),
        ),
      );
    }

    if (_session == null || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No exam data')),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final isLastQuestion = _currentIndex == _questions.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _showLeaveDialog(context);
        if (shouldLeave == true && context.mounted) {
          context.go('/exams');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () async {
              final shouldLeave = await _showLeaveDialog(context);
              if (shouldLeave == true && context.mounted) {
                context.go('/exams');
              }
            },
          ),
          title: _session!.endsAt.isAfter(DateTime.now())
              ? ExamTimer(
                  endsAt: _session!.endsAt,
                  onExpire: _autoSubmit,
                )
              : null,
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildProgressBar(context, progress, isDark),
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
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
          color: AppColors.accent,
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isLastQuestion, bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            if (_currentIndex > 0)
              Expanded(
                child: AppButton(
                  label: 'Back',
                  type: AppButtonType.ghost,
                  onPressed: () => setState(() => _currentIndex--),
                ),
              ),
            if (_currentIndex > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppButton(
                label: isLastQuestion ? 'Submit' : 'Next',
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
    );
  }

  void _onAnswerSelected(String optionLabel) {
    final question = _questions[_currentIndex];
    setState(() {
      _localAnswers[question.id] = optionLabel;
    });
  }

  Future<void> _nextQuestion() async {
    final question = _questions[_currentIndex];
    if (_localAnswers[question.id] != null) {
      try {
        await ref.read(examsRepositoryProvider).saveAnswer(
              _session!.id,
              question.id,
              _localAnswers[question.id]!,
            );
      } catch (_) {}
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
        context.go('/exams/${widget.examId}/result', extra: {'score': score, 'timedOut': false});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
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
        context.go('/exams/${widget.examId}/result', extra: {'score': score, 'timedOut': true});
      }
    } catch (_) {
      if (mounted) {
        context.go('/exams/${widget.examId}/result', extra: {'timedOut': true});
      }
    }
  }

  Future<bool?> _showLeaveDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave exam?'),
        content: const Text('Your progress will be saved, but the timer will keep running. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Leave', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}