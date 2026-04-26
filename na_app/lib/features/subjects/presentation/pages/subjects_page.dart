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
import 'package:animate_do/animate_do.dart';

class SubjectsPage extends ConsumerWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () => ref.read(subjectsListProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: _buildHeader(context, isDark),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 500),
                    child: _buildCodeEntryCard(context, isDark),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                subjectsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: FadeIn(
                      child: EmptyState(
                        icon: LucideIcons.circleAlert,
                        title: 'تعذر تحميل المواد',
                        message: 'حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
                        actionLabel: 'إعادة المحاولة',
                        onAction: () { ref.invalidate(subjectsListProvider); },
                      ),
                    ),
                  ),
                  data: (subjects) {
                    if (subjects.isEmpty) {
                      return SliverFillRemaining(
                        child: FadeIn(
                          child: EmptyState(
                            icon: LucideIcons.bookOpen,
                            title: 'لا توجد مواد بعد',
                            message: 'أدخل كود المادة لفتح أول مادة دراسية لك.',
                            actionLabel: 'إدخال الكود',
                            onAction: () => context.go('/subjects/enter-code'),
                          ),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'المواد الدراسية',
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.library,
              color: isDark ? AppColors.darkAccent : AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeEntryCard(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => context.push('/subjects/enter-code'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.15),
                (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.05),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  LucideIcons.keyRound, 
                  color: isDark ? AppColors.darkAccent : AppColors.accent, 
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هل لديك كود مادة؟',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'انقر هنا لفتح مادة جديدة',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronLeft, // Left arrow for RTL
                color: isDark ? AppColors.darkAccent : AppColors.accent, 
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Subject> subjects) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 220, // Slightly taller for the new design
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final subject = subjects[index];
            return FadeInUp(
              delay: Duration(milliseconds: 200 + (index * 50)),
              duration: const Duration(milliseconds: 500),
              child: SubjectCard(
                subject: subject,
                onTap: () {
                  if (subject.isUnlocked) {
                    context.push('/subjects/${subject.id}');
                  } else {
                    context.push('/subjects/enter-code');
                  }
                },
              ),
            );
          },
          childCount: subjects.length,
        ),
      ),
    );
  }
}
