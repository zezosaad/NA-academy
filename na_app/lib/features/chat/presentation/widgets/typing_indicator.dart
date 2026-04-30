import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:na_app/core/widgets/typing_indicator.dart';
import 'package:na_app/core/theme/app_colors.dart';

class ChatTypingIndicator extends StatelessWidget {
  final String userName;
  final bool isTyping;

  const ChatTypingIndicator({
    super.key,
    required this.userName,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTyping) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TypingIndicatorWidget(
            isDark: isDark,
          ),
          const SizedBox(width: 6),
          Text(
            'chat.thread.isTyping'.tr(namedArgs: {'name': userName}),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}