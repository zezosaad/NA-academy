import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/core/widgets/code_input.dart';
import 'package:na_app/features/exams/data/exams_repository.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';
import 'package:na_app/features/subjects/domain/activation_result.dart';
import 'package:na_app/features/subjects/data/subjects_repository.dart';

class EnterExamCodePage extends ConsumerStatefulWidget {
  final String examId;
  const EnterExamCodePage({super.key, required this.examId});

  @override
  ConsumerState<EnterExamCodePage> createState() => _EnterExamCodePageState();
}

class _EnterExamCodePageState extends ConsumerState<EnterExamCodePage> {
  String _code = '';
  bool _isLoading = false;
  ApiException? _error;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final examAsync = ref.watch(examsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Enter Exam Code'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              examAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (exams) {
                  final exam = exams.whereType<Exam>().firstWhere(
                        (e) => e.id == widget.examId,
                        orElse: () => Exam(id: widget.examId, title: 'Exam', subjectId: ''),
                      );
                  return _buildExamSummary(context, exam, isDark);
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Enter your exam code',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Type or paste the 6-character code provided by your teacher',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CodeInputField(
                length: 6,
                onChanged: (code) => setState(() => _code = code),
                onCompleted: null,
                enabled: !_isLoading,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!.message,
                  style: TextStyle(color: isDark ? AppColors.darkDanger : AppColors.danger, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: 'Unlock and start exam',
                type: AppButtonType.primary,
                onPressed: _code.length == 6 && !_isLoading ? _activateAndStart : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamSummary(BuildContext context, Exam exam, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exam.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.clock, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${exam.durationMinutes} min', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 14),
              Icon(LucideIcons.clipboardList, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${exam.questionCount} questions', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _activateAndStart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subjectsRepo = ref.read(subjectsRepositoryProvider);
      final result = await subjectsRepo.activateCode(_code.toUpperCase());

      if (result is ActivationSuccess) {
        if (result.codeType == 'exam') {
          try {
            final examsRepo = ref.read(examsRepositoryProvider);
            await examsRepo.getExamAndStart(result.targetId);
            if (mounted) {
              context.go('/exams/${result.targetId}/take');
            }
          } on ApiException catch (e) {
            if (!mounted) return;
            setState(() { _error = e; });
          } catch (e) {
            if (!mounted) return;
            setState(() {
              _error = ApiException(statusCode: 0, code: 'SESSION_START_FAILED', message: e.toString());
            });
          }
        } else {
          if (mounted) {
            context.go('/subjects/${result.targetId}');
          }
        }
      } else if (result is ActivationFailure) {
        switch (result.reason) {
          case ActivationErrorReason.expired:
            if (mounted) {
              context.push('/subjects/code-expired', extra: {'code': _code.toUpperCase(), 'expiredAt': result.expiredAt});
            }
          case ActivationErrorReason.alreadyUsed:
            if (mounted) {
              context.push('/subjects/code-used', extra: {'code': _code.toUpperCase(), 'consumedAt': result.consumedAt});
            }
          case ActivationErrorReason.deviceMismatch:
            if (!mounted) return;
            setState(() {
              _error = ApiException(statusCode: 403, code: 'DEVICE_MISMATCH', message: 'This code is linked to a different device.');
            });
          case ActivationErrorReason.rateLimited:
            if (!mounted) return;
            setState(() {
              _error = ApiException(statusCode: 429, code: 'RATE_LIMITED', message: 'Too many attempts. Please wait and try again.');
            });
          case ActivationErrorReason.invalid:
            if (!mounted) return;
            setState(() {
              _error = ApiException(statusCode: 400, code: 'BAD_CODE', message: 'Invalid code. Please try again.');
            });
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiException(statusCode: 0, code: 'UNKNOWN', message: e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}