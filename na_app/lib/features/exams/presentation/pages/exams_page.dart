import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/exams/data/exams_repository.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

class ExamsPage extends ConsumerWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(examsListProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.read(examsListProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              examsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: EmptyState(
                    icon: LucideIcons.circleAlert,
                    title: 'Could not load exams',
                    message: e.toString(),
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(examsListProvider),
                  ),
                ),
                data: (exams) {
                  if (exams.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: LucideIcons.fileText,
                        title: 'No exams available',
                        message: 'Exams will appear here once you unlock a subject with an exam code.',
                      ),
                    );
                  }
                  return _buildExamList(context, exams);
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Text('Exams', style: Theme.of(context).textTheme.displayLarge),
    );
  }

  Widget _buildExamList(BuildContext context, List<Exam> exams) {
    final completed = exams.where((e) => e.status == ExamStatus.completed).toList();
    final completedIds = completed.map((e) => e.id).toSet();
    final available = exams.where((e) => !completedIds.contains(e.id)).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        if (available.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text('Available', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
          ),
          ...available.map((exam) => _ExamCard(exam: exam)),
          const SizedBox(height: 20),
        ],
        if (completed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text('Completed', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
          ),
          ...completed.map((exam) => _CompletedExamCard(exam: exam)),
        ],
      ]),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/exams/${exam.id}/enter-code'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exam.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (exam.attemptsRemaining > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${exam.attemptsRemaining} attempt${exam.attemptsRemaining > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
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
          ),
        ),
      ),
    );
  }
}

class _CompletedExamCard extends StatelessWidget {
  final Exam exam;
  const _CompletedExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = (exam.lastScore ?? 0).round();
    final isPass = score >= 70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/exams/${exam.id}/result', extra: {
            'score': ExamScore(sessionId: '', score: exam.lastScore ?? 0),
            'timedOut': false,
          }),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${score.round()}',
                    style: TextStyle(
                      color: isPass
                          ? (isDark ? AppColors.darkSuccess : AppColors.success)
                          : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Completed', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}