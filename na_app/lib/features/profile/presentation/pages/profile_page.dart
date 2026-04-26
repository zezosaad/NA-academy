import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/error_toast.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:na_app/features/profile/data/profile_repository.dart';
import 'package:na_app/features/profile/presentation/widgets/weekly_chart.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(profileUserProvider);
    final analyticsAsync = ref.watch(profileAnalyticsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              ref.invalidate(profileUserProvider);
              ref.invalidate(profileAnalyticsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, ref, isDark),
                  const SizedBox(height: 32),
                  userAsync.when(
                    data: (user) => _buildProfileCard(context, user, isDark),
                    loading: () => const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )),
                    error: (e, _) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ErrorToast.show(context, e);
                      });
                      return _buildProfileCard(context, null, isDark);
                    },
                  ),
                  const SizedBox(height: 24),
                  analyticsAsync.when(
                    data: (analytics) => _buildStatTiles(context, analytics, isDark),
                    loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    ),
                    error: (e, st) => _buildStatTiles(context, null, isDark),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'نشاطك الأسبوعي', isDark),
                  const SizedBox(height: 16),
                  analyticsAsync.when(
                    data: (analytics) => WeeklyChart(
                      values: analytics.weeklyActivity,
                      highlightIndex: _todayIndex(),
                    ),
                    loading: () => const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                    ),
                    error: (e, st) => WeeklyChart(
                      values: [],
                      highlightIndex: _todayIndex(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, 'الإعدادات والمحتوى', isDark),
                  const SizedBox(height: 16),
                  _buildSettingsList(context, isDark),
                  const SizedBox(height: 48),
                  _buildSignOutButton(context, ref, isDark),
                ],
              ),
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

  Widget _buildSectionTitle(BuildContext context, String title, bool isDark) {
    return FadeInRight(
      duration: const Duration(milliseconds: 500),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isDark) {
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'حسابك',
            style: GoogleFonts.cairo(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Semantics(
            button: true,
            label: 'إعدادات الحساب',
            child: GestureDetector(
              onTap: () => context.push('/profile/settings'),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(LucideIcons.settings, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user, bool isDark) {
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final accentSoft = isDark ? AppColors.darkAccentSoft : AppColors.accentSoft;

    final name = user != null ? user.name as String : 'طالب علم';
    final email = user != null ? user.email as String : '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'طالب',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w800,
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

  Widget _buildStatTiles(BuildContext context, dynamic analytics, bool isDark) {
    final secondaryColor = isDark ? AppColors.darkSecondary : AppColors.secondary;
    final secondarySoft = isDark ? AppColors.darkSecondarySoft : AppColors.secondarySoft;
    final accentColor = isDark ? AppColors.darkAccentDeep : AppColors.accentDeep;
    final accentSoft = isDark ? AppColors.darkAccentSoft : AppColors.accentSoft;

    final streak = analytics != null ? analytics.streakDays as int : 0;
    final lessons = analytics != null ? analytics.lessonsCompleted as int : 0;
    final exams = analytics != null ? analytics.examsTaken as int : 0;

    return FadeInUp(
      delay: const Duration(milliseconds: 200),
      child: Row(
        children: [
          Expanded(
            child: _ModernStatTile(
              icon: LucideIcons.flame,
              label: 'استمرارية',
              value: '$streak',
              unit: 'أيام',
              color: secondaryColor,
              bgColor: secondarySoft,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModernStatTile(
              icon: LucideIcons.bookOpen,
              label: 'دروس',
              value: '$lessons',
              unit: 'مكتملة',
              color: accentColor,
              bgColor: accentSoft,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModernStatTile(
              icon: LucideIcons.fileText,
              label: 'اختبارات',
              value: '$exams',
              unit: 'منجزة',
              color: secondaryColor,
              bgColor: secondarySoft,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, bool isDark) {
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final sunkenColor = isDark ? AppColors.darkBgSunken : AppColors.bgSunken;

    final items = [
      (
        icon: LucideIcons.trophy,
        label: 'الشهادات',
        hint: 'عرض شهاداتك المكتملة',
      ),
      (
        icon: LucideIcons.bookmark,
        label: 'الدروس المحفوظة',
        hint: 'الدروس التي قمت بحفظها',
      ),
    ];

    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return InkWell(
              onTap: () {}, // Future implementation
              borderRadius: BorderRadius.vertical(
                top: index == 0 ? const Radius.circular(24) : Radius.zero,
                bottom: index == items.length - 1 ? const Radius.circular(24) : Radius.zero,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: index < items.length - 1
                      ? Border(bottom: BorderSide(color: borderColor))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: sunkenColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, size: 20, color: textColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          Text(
                            item.hint,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronLeft, size: 18, color: mutedColor),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref, bool isDark) {
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;

    return FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Center(
        child: TextButton.icon(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  backgroundColor: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text(
                    'تسجيل الخروج',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w900),
                  ),
                  content: Text(
                    'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('إلغاء', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        'تسجيل الخروج',
                        style: GoogleFonts.cairo(color: dangerColor, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            );
            if (confirmed == true && context.mounted) {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go('/splash');
              }
            }
          },
          icon: Icon(LucideIcons.logOut, size: 20, color: dangerColor),
          label: Text(
            'تسجيل الخروج',
            style: GoogleFonts.cairo(
              color: dangerColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            backgroundColor: dangerColor.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

class _ModernStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bgColor;
  final bool isDark;

  const _ModernStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bgColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
