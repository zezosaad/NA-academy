import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';

class Composer extends StatefulWidget {
  final ValueChanged<String>? onSendText;
  final ValueChanged<String>? onTextChanged;
  final ValueChanged<File>? onSendImage;
  final bool enabled;
  final String? hintText;

  const Composer({
    super.key,
    this.onSendText,
    this.onTextChanged,
    this.onSendImage,
    this.enabled = true,
    this.hintText,
  });

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _isComposing) {
      setState(() => _isComposing = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText?.call(text);
    _controller.clear();
    setState(() => _isComposing = false);
  }

  Future<void> _handleImagePick() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    final file = File(image.path);
    final fileSize = await file.length();
    const maxBytes = 10 * 1024 * 1024;

    if (fileSize > maxBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image must be smaller than 10 MB'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final mimeType = image.mimeType ?? 'image/jpeg';
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
    if (!allowedTypes.contains(mimeType)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only JPEG, PNG, WebP, and HEIC images are allowed'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    widget.onSendImage?.call(file);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.bgCanvas,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (widget.enabled)
              IconButton(
                icon: Icon(
                  LucideIcons.imagePlus,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  size: 22,
                ),
                onPressed: _handleImagePick,
                tooltip: 'Attach image',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Type a message...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppShapes.inputRadius),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.darkBgSunken : AppColors.bgSurface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                LucideIcons.send,
                color: _isComposing && widget.enabled
                    ? AppColors.accent
                    : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                size: 22,
              ),
              onPressed: _isComposing && widget.enabled ? _handleSend : null,
              tooltip: 'Send',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }
}