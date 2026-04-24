import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/core/widgets/code_input.dart';

class BottomSheetCode extends StatefulWidget {
  final Future<void> Function(String code) onsubmit;

  const BottomSheetCode({super.key, required this.onsubmit});

  @override
  State<BottomSheetCode> createState() => _BottomSheetCodeState();
}

class _BottomSheetCodeState extends State<BottomSheetCode> {
  String _code = '';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_code.length != 6 || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onsubmit(_code);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter subject code',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: CodeInputField(
              length: 6,
              onCompleted: () => setState(() {}),
              onChanged: (code) => setState(() => _code = code),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Unlock',
            onPressed: _code.length == 6 ? _submit : null,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }
}

Future<void> showCodeBottomSheet(
  BuildContext context, {
  required Future<void> Function(String code) onSubmit,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBgSurface
        : AppColors.bgElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BottomSheetCode(onsubmit: onSubmit),
  );
}
