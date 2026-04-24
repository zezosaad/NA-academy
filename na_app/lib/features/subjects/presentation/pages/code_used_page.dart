import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';

class CodeUsedPage extends StatelessWidget {
  final String code;
  final DateTime? consumedAt;

  const CodeUsedPage({super.key, required this.code, this.consumedAt});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.triangleAlert, size: 28, color: AppColors.warning),
            ),
            const SizedBox(height: 24),
            Text(
              'Code already used',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'This activation code has already been redeemed.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                code,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (consumedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Used on ${_formatDate(consumedAt!)}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              label: 'Try another code',
              onPressed: () => context.go('/subjects/enter-code'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Message teacher',
              onPressed: () => context.go('/chat'),
              type: AppButtonType.ghost,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
