import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:na_app/features/subjects/presentation/widgets/subject_card.dart';

class SubjectsPage extends ConsumerWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsListProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => ref.read(subjectsListProvider.notifier).refresh(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: _buildCodeEntryCard(context)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              subjectsAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: EmptyState(
                    icon: LucideIcons.circleAlert,
                    title: 'Could not load subjects',
                    message: e.toString(),
                    actionLabel: 'Retry',
                    onAction: () { ref.invalidate(subjectsListProvider); },
                  ),
                ),
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: LucideIcons.bookOpen,
                        title: 'No subjects yet',
                        message: 'Enter a subject code to unlock your first subject.',
                        actionLabel: 'Enter code',
                        onAction: () => context.go('/subjects/enter-code'),
                      ),
                    );
                  }
                  return _buildGrid(context, subjects);
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        'Learn',
        style: Theme.of(context).textTheme.displayLarge,
      ),
    );
  }

  Widget _buildCodeEntryCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/subjects/enter-code'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.keyRound, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Have a subject code?',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap here to unlock a new subject',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.accent.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Subject> subjects) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 210,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subject = subjects[index];
            return SubjectCard(
              subject: subject,
              onTap: () {
                if (subject.isUnlocked) {
                  context.go('/subjects/${subject.id}');
                } else {
                  context.push('/subjects/enter-code');
                }
              },
            );
          },
          childCount: subjects.length,
        ),
      ),
    );
  }
}
