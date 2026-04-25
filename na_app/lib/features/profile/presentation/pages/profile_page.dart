import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/error_toast.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:na_app/features/profile/data/profile_repository.dart';
import 'package:na_app/features/profile/presentation/widgets/stat_tile.dart';
import 'package:na_app/features/profile/presentation/widgets/weekly_chart.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(profileUserProvider);
    final analyticsAsync = ref.watch(profileAnalyticsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(profileUserProvider);
            ref.invalidate(profileAnalyticsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ref),
                const SizedBox(height: 20),
                userAsync.when(
                  data: (user) => _buildProfileCard(context, user),
                  loading: () => const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  )),
                  error: (e, _) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ErrorToast.show(context, e);
                    });
                    return _buildProfileCard(
                      context,
                      null,
                    );
                  },
                ),
                const SizedBox(height: 14),
                analyticsAsync.when(
                  data: (analytics) => _buildStatTiles(context, analytics),
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => _buildStatTiles(context, null),
                ),
                const SizedBox(height: 20),
                analyticsAsync.when(
                  data: (analytics) => WeeklyChart(
                    values: analytics.weeklyActivity,
                    highlightIndex: _todayIndex(),
                  ),
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, st) => WeeklyChart(
                    values: [],
                    highlightIndex: _todayIndex(),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSettingsList(context),
                const SizedBox(height: 20),
                _buildSignOutButton(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _todayIndex() {
    final dow = DateTime.now().weekday;
    return dow >= 1 && dow <= 7 ? dow - 1 : 6;
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'You',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Semantics(
              button: true,
              label: 'Open settings',
              child: GestureDetector(
                onTap: () => context.push('/profile/settings'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Icon(LucideIcons.settings, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final accentSoft =
        isDark ? AppColors.darkAccentSoft : AppColors.accentSoft;
    final accentDeep =
        isDark ? AppColors.darkAccentDeep : AppColors.accentDeep;

    final name = user != null ? user.name as String : 'Student';
    final email = user != null ? user.email as String : '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 20),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Student',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: accentDeep,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTiles(BuildContext context, dynamic analytics) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.darkSecondary : AppColors.secondary;
    final secondarySoft =
        isDark ? AppColors.darkSecondarySoft : AppColors.secondarySoft;
    final accentColor =
        isDark ? AppColors.darkAccentDeep : AppColors.accentDeep;
    final accentSoft =
        isDark ? AppColors.darkAccentSoft : AppColors.accentSoft;

    final streak = analytics != null ? analytics.streakDays as int : 0;
    final lessons =
        analytics != null ? analytics.lessonsCompleted as int : 0;
    final exams = analytics != null ? analytics.examsTaken as int : 0;

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: StatTile(
              icon: LucideIcons.flame,
              label: 'Streak',
              value: '$streak',
              unit: 'days',
              iconColor: secondaryColor,
              iconBgColor: secondarySoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              icon: LucideIcons.bookOpen,
              label: 'Lessons',
              value: '$lessons',
              iconColor: accentColor,
              iconBgColor: accentSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              icon: LucideIcons.fileText,
              label: 'Exams',
              value: '$exams',
              iconColor: secondaryColor,
              iconBgColor: secondarySoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor =
        isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final sunkenColor =
        isDark ? AppColors.darkBgSunken : AppColors.bgSunken;

    final items = [
      (
        icon: LucideIcons.trophy,
        label: 'Certificates',
        hint: 'View earned certificates',
      ),
      (
        icon: LucideIcons.bookmark,
        label: 'Saved lessons',
        hint: 'Your bookmarked lessons',
      ),
    ];

    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: index < items.length - 1
                    ? Border(
                        bottom: BorderSide(color: borderColor),
                      )
                    : null,
              ),
              child: Semantics(
                button: true,
                label: item.label,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: sunkenColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, size: 16, color: textColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 15),
                      ),
                    ),
                    Text(
                      item.hint,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: mutedColor),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronRight, size: 16, color: mutedColor),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    final dangerColor =
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkDanger
            : AppColors.danger;

    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Center(
        child: Semantics(
          button: true,
          label: 'Sign out',
          child: TextButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out'),
                  content: const Text(
                      'Are you sure you want to sign out of your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text('Sign out',
                          style: TextStyle(color: dangerColor)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/splash');
                }
              }
            },
            icon: Icon(LucideIcons.logOut, size: 18, color: dangerColor),
            label: Text(
              'Sign out',
              style: TextStyle(
                color: dangerColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(44, 44),
            ),
          ),
        ),
      ),
    );
  }
}
