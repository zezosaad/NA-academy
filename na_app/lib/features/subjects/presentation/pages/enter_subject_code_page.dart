import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/core/widgets/code_input.dart';
import 'package:na_app/features/subjects/domain/activation_result.dart';
import 'package:na_app/features/subjects/presentation/controllers/subjects_controller.dart';

class EnterSubjectCodePage extends ConsumerStatefulWidget {
  final String? subjectTitle;

  const EnterSubjectCodePage({super.key, this.subjectTitle});

  @override
  ConsumerState<EnterSubjectCodePage> createState() => _EnterSubjectCodePageState();
}

const _subjectCodeLength = 12;

class _EnterSubjectCodePageState extends ConsumerState<EnterSubjectCodePage> {
  String _code = '';
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_code.length != _subjectCodeLength || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final activate = ref.read(activateCodeProvider);
      final result = await activate(_code);

      if (!mounted) return;

      switch (result) {
        case ActivationSuccess(:final codeType, :final targetId):
          if (codeType == 'subject') {
            context.go('/subjects/$targetId/unlocking');
          } else {
            context.go('/exams/$targetId/enter-code');
          }
        case ActivationFailure(:final reason, :final expiredAt, :final consumedAt):
          switch (reason) {
            case ActivationErrorReason.expired:
              context.go('/subjects/code-expired', extra: {
                'code': _code,
                'expiredAt': expiredAt,
              });
            case ActivationErrorReason.alreadyUsed:
              context.go('/subjects/code-used', extra: {
                'code': _code,
                'consumedAt': consumedAt,
              });
            case ActivationErrorReason.rateLimited:
              setState(() => _error = 'Too many attempts. Please wait and try again.');
            case ActivationErrorReason.deviceMismatch:
              setState(() => _error = 'This code is linked to a different device.');
            case ActivationErrorReason.invalid:
              setState(() => _error = 'Invalid code. Please check and try again.');
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Enter subject code',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              widget.subjectTitle != null
                  ? 'Enter the $_subjectCodeLength-character code to unlock "${widget.subjectTitle}".'
                  : 'Enter the $_subjectCodeLength-character code from your teacher to unlock a new subject.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: CodeInputField(
                length: _subjectCodeLength,
                onCompleted: () {
                  // _code is already updated via onChanged
                },
                onChanged: (code) {
                  setState(() {
                    _code = code;
                    _error = null;
                  });
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.circleAlert, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            AppButton(
              label: 'Unlock',
              onPressed: _code.length == _subjectCodeLength ? _submit : null,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Codes are provided by your teacher or administrator.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
