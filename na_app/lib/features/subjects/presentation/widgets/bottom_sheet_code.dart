import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:flutter/services.dart';

class BottomSheetCode extends StatefulWidget {
  final Future<void> Function(String code) onsubmit;

  const BottomSheetCode({super.key, required this.onsubmit});

  @override
  State<BottomSheetCode> createState() => _BottomSheetCodeState();
}

const _bottomSheetCodeLength = 12;

class _BottomSheetCodeState extends State<BottomSheetCode> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != _bottomSheetCodeLength || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.onsubmit(code);
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
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: _bottomSheetCodeLength,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter $_bottomSheetCodeLength-character code',
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBgSurface
                  : AppColors.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkBorderSubtle
                      : AppColors.borderSubtle,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkAccent
                      : AppColors.accent,
                  width: 1.5,
                ),
              ),
            ),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Unlock',
            onPressed: _controller.text.trim().length == _bottomSheetCodeLength
                ? _submit
                : null,
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
