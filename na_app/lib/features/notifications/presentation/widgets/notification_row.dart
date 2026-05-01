import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:na_app/core/storage/app_database.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';

class NotificationRow extends StatelessWidget {
  final NotificationsInboxData item;
  final VoidCallback? onTap;

  const NotificationRow({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = item.readAt == null;

    final bgColor = isUnread
        ? (isDark ? AppColors.darkAccentSoft : AppColors.accentSoft.withValues(alpha: 0.3))
        : (isDark ? AppColors.darkBgSurface : AppColors.bgSurface);

    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bodyColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
          border: Border.all(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                          color: titleColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: bodyColor,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimestamp(item.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                        ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkAccent : AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int millis) {
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'notifications.now'.tr();
    if (diff.inMinutes < 60) {
      return 'notifications.mins_ago'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24 && date.day == now.day) {
      return 'notifications.today'.tr();
    }
    if (diff.inDays == 1) return 'notifications.yesterday'.tr();
    return DateFormat.yMMMd().format(date);
  }
}
