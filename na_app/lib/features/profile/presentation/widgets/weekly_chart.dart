import 'package:flutter/material.dart';
import 'package:na_app/core/theme/app_colors.dart';

class WeeklyChart extends StatelessWidget {
  final List<int> values;
  final int highlightIndex;

  const WeeklyChart({
    super.key,
    required this.values,
    this.highlightIndex = 6,
  });

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBgSurface : AppColors.bgSurface;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    final accentSoft =
        isDark ? AppColors.darkAccentSoft : AppColors.accentSoft;
    final activeTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final mutedTextColor =
        isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final maxVal = values.fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    final safeMax = maxVal > 0 ? maxVal : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Semantics(
        label: 'Weekly activity chart',
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'This week',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  values.length.clamp(0, 7),
                  (index) {
                    final v = index < values.length ? values[index] : 0;
                    final fraction = (v / safeMax).clamp(0.0, 1.0);
                    final isHighlighted = index == highlightIndex;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: fraction == 0 ? 0.05 : fraction,
                                child: Container(
                                  width: 12,
                                  decoration: BoxDecoration(
                                    color: isHighlighted
                                        ? accentColor
                                        : accentSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            index < _labels.length
                                ? _labels[index]
                                : '',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: isHighlighted
                                      ? activeTextColor
                                      : mutedTextColor,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
