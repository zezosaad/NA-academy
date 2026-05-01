import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/storage/app_database.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/features/notifications/data/notifications_repository.dart';
import 'package:na_app/features/notifications/presentation/controllers/inbox_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationDetailPage extends ConsumerStatefulWidget {
  final String notificationId;

  const NotificationDetailPage({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends ConsumerState<NotificationDetailPage> {
  NotificationsInboxData? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  Future<void> _loadItem() async {
    final repository = ref.read(notificationsRepositoryProvider);
    final item = await repository.getById(widget.notificationId);
    if (!mounted) return;
    setState(() {
      _item = item;
      _loading = false;
    });

    if (item != null && item.readAt == null) {
      ref.read(inboxControllerProvider).markRead(widget.notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(title: Text('notifications.title'.tr())),
        body: Center(child: Text('notifications.notFound'.tr())),
      );
    }

    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bodyColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    Map<String, dynamic>? payloadData;
    if (_item?.data != null) {
      try {
        payloadData = jsonDecode(_item!.data!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: Text('notifications.title'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _item!.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
                borderRadius: BorderRadius.circular(AppShapes.radiusPill),
              ),
              child: Text(
                DateFormat.yMMMd(context.locale.languageCode)
                    .add_jm()
                    .format(DateTime.fromMillisecondsSinceEpoch(_item!.createdAt)),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: mutedColor,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _item!.body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: bodyColor,
                    height: 1.7,
                  ),
            ),
            if (payloadData != null) ...[
              const SizedBox(height: 24),
              _buildPayloadSection(context, isDark, payloadData),
              const SizedBox(height: 16),
              _buildPayloadAction(payloadData),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPayloadSection(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> data,
  ) {
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'notifications.payload'.tr(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSunken : AppColors.bgSunken,
            borderRadius: BorderRadius.circular(AppShapes.radiusSmall),
          ),
          child: Text(
            const JsonEncoder.withIndent('  ').convert(data),
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: mutedColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayloadAction(Map<String, dynamic> data) {
    final type = data['type'];
    final url = data['url'];
    if (type != 'url' || url is! String || url.isEmpty) {
      return const SizedBox.shrink();
    }

    return FilledButton(
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
        child: Text('notifications.open_url'.tr()),
      );
  }
}
