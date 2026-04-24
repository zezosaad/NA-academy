import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

class QuestionCard extends StatelessWidget {
  final ExamQuestion question;
  final int currentIndex;
  final int totalCount;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;
  final bool enabled;

  const QuestionCard({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.totalCount,
    this.selectedAnswer,
    required this.onAnswerSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Question ${currentIndex + 1} of $totalCount',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            question.text,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 24),
        ...question.options.map((option) => _OptionTile(
              option: option,
              isSelected: selectedAnswer == option.label,
              onTap: enabled ? () => onAnswerSelected(option.label) : null,
              isDark: isDark,
            )),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final QuestionOption option;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isDark;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? AppColors.accent.withValues(alpha: isDark ? 0.15 : 0.08)
        : (isDark ? AppColors.darkBgSurface : AppColors.bgSurface);
    final borderColor = isSelected
        ? AppColors.accent
        : (isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle);
    final textColor = isSelected
        ? AppColors.accent
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppShapes.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppShapes.cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppShapes.cardRadius),
              border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : borderColor,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}