import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/widgets/button.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';

class VerifyResetCodePage extends ConsumerStatefulWidget {
  final String email;

  const VerifyResetCodePage({super.key, required this.email});

  @override
  ConsumerState<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends ConsumerState<VerifyResetCodePage> {
  static const int _codeLength = 6;
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _focusNodes;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _digitControllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _digitControllers.map((c) => c.text).join();
  bool get _isComplete => _code.length == _codeLength && !_code.contains(RegExp(r'\D'));

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Likely a paste — distribute digits across fields.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _codeLength; i++) {
        _digitControllers[i].text = i < digits.length ? digits[i] : '';
      }
      final nextIndex = (digits.length).clamp(0, _codeLength - 1);
      _focusNodes[nextIndex].requestFocus();
      setState(() {});
      if (_isComplete) _verify();
      return;
    }

    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
    if (_isComplete) _verify();
  }

  void _onDigitBackspace(int index) {
    if (index > 0 && _digitControllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
      _digitControllers[index - 1].clear();
      setState(() {});
    }
  }

  Future<void> _verify() async {
    if (_isVerifying) return;
    if (!_isComplete) return;
    FocusScope.of(context).unfocus();

    setState(() => _isVerifying = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .verifyResetCode(email: widget.email, code: _code);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.ok && result.token != null) {
      context.go('/auth/reset-password?token=${Uri.encodeQueryComponent(result.token!)}');
    } else {
      _clearCode();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'auth.verifyResetCode.failure'.tr(),
          ),
        ),
      );
    }
  }

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() => _isResending = true);

    final result =
        await ref.read(authControllerProvider.notifier).forgotPassword(email: widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);
    _clearCode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok
              ? 'auth.verifyResetCode.resent'.tr()
              : (result.errorMessage ?? 'auth.forgotPassword.failure'.tr()),
        ),
      ),
    );
  }

  void _clearCode() {
    for (final c in _digitControllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => context.go('/auth/forgot-password'),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkAccentSoft : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  LucideIcons.mailCheck,
                  size: 32,
                  color: isDark ? AppColors.darkAccent : AppColors.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'auth.verifyResetCode.title'.tr(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'auth.verifyResetCode.subtitle'.tr(namedArgs: {'email': widget.email}),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_codeLength, (i) => _buildDigitBox(i, isDark)),
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'auth.verifyResetCode.submit'.tr(),
                onPressed: _isComplete ? _verify : null,
                isLoading: _isVerifying,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'auth.verifyResetCode.resend'.tr(),
                type: AppButtonType.ghost,
                onPressed: _isResending ? null : _resend,
                isLoading: _isResending,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index, bool isDark) {
    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _digitControllers[index].text.isEmpty) {
            _onDigitBackspace(index);
          }
        },
        child: TextField(
          controller: _digitControllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
          onChanged: (v) => _onDigitChanged(index, v),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppShapes.inputRadius),
              borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppShapes.inputRadius),
              borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppShapes.inputRadius),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkAccent : AppColors.accent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
