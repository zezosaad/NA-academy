import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';

class CodeInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final VoidCallback? onCompleted;
  final bool enabled;

  const CodeInputField({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  State<CodeInputField> createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<CodeInputField> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _keyboardFocusNodes;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.length);
  }

  void _initControllers(int length) {
    _focusNodes = List.generate(length, (_) => FocusNode());
    _controllers = List.generate(length, (_) => TextEditingController());
    _keyboardFocusNodes = List.generate(length, (_) => FocusNode());
  }

  void _disposeControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyboardFocusNodes) {
      f.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant CodeInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) {
      _disposeControllers();
      _initControllers(widget.length);
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  String get code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.isEmpty) {
      _notifyChanged();
      return;
    }

    if (value.length > 1) {
      _handlePaste(value);
      return;
    }

    final char = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (char.isEmpty) {
      _controllers[index].clear();
      _notifyChanged();
      return;
    }

    _controllers[index].text = char;
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    _notifyChanged();
  }

  void _handlePaste(String pastedValue) {
    final chars = pastedValue
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .toUpperCase()
        .split('');

    for (int i = 0; i < widget.length; i++) {
      if (i < chars.length) {
        _controllers[i].text = chars[i];
      } else {
        _controllers[i].clear();
      }
    }

    if (chars.isNotEmpty) {
      final focusIndex = chars.length < widget.length ? chars.length : widget.length - 1;
      _focusNodes[focusIndex].requestFocus();
    }

    _notifyChanged();
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].clear();
        _focusNodes[index - 1].requestFocus();
        _notifyChanged();
      }
    }
  }

  void _notifyChanged() {
    final fullCode = code;
    widget.onChanged(fullCode);
    if (fullCode.length == widget.length && widget.onCompleted != null) {
      widget.onCompleted!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.length, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: 48,
              height: 56,
              child: KeyboardListener(
                focusNode: _keyboardFocusNodes[index],
                onKeyEvent: (event) => _onKeyDown(index, event),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  maxLength: 1,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkBgSurface
                        : AppColors.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppShapes.inputRadius),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorderSubtle
                            : AppColors.borderSubtle,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppShapes.inputRadius),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorderSubtle
                            : AppColors.borderSubtle,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppShapes.inputRadius),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkAccent : AppColors.accent,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  onChanged: (value) => _onChanged(index, value),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
