import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/utils/date_formatter.dart';
import 'package:na_app/features/subjects/presentation/widgets/code_error_actions.dart';
import 'package:na_app/features/subjects/presentation/widgets/code_info_card.dart';

class CodeExpiredPage extends StatelessWidget {
  final String code;
  final DateTime? expiredAt;

  const CodeExpiredPage({super.key, required this.code, this.expiredAt});

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
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.clock, size: 28, color: AppColors.danger),
            ),
            const SizedBox(height: 24),
            Text(
              'Code expired',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            CodeInfoCard(code: code),
            if (expiredAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'This code expired on ${formatDateTime(expiredAt!)}',
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
