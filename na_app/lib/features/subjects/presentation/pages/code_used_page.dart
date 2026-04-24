import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/utils/date_formatter.dart';
import 'package:na_app/features/subjects/presentation/widgets/code_error_actions.dart';
import 'package:na_app/features/subjects/presentation/widgets/code_info_card.dart';

class CodeUsedPage extends StatelessWidget {
  final String code;
  final DateTime? consumedAt;

  const CodeUsedPage({super.key, required this.code, this.consumedAt});

  @override
  Widget build(BuildContext context) {
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
            CodeInfoCard(code: code),
            if (consumedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Used on ${formatDateTime(consumedAt!)}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 32),
            const CodeErrorActions(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

}
