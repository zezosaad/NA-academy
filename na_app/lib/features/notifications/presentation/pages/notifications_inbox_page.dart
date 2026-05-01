import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/storage/app_database.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/features/notifications/presentation/controllers/inbox_controller.dart';
import 'package:na_app/features/notifications/presentation/widgets/notification_row.dart';

class NotificationsInboxPage extends ConsumerStatefulWidget {
  const NotificationsInboxPage({super.key});

  @override
  ConsumerState<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends ConsumerState<NotificationsInboxPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inboxControllerProvider).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inboxAsync = ref.watch(inboxStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications.inbox_title'.tr()),
        actions: [
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            initialData: const [ConnectivityResult.wifi],
            builder: (context, snapshot) {
              final isOnline = snapshot.data?.any(
                    (r) => r != ConnectivityResult.none,
                  ) ??
                  true;
              if (!isOnline) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  LucideIcons.checkCheck,
                  size: 20,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                tooltip: 'notifications.mark_all_read'.tr(),
                onPressed: () async {
                  await ref.read(inboxControllerProvider).markAllRead();
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(inboxControllerProvider).refresh(),
        child: inboxAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildError(e),
          data: (items) {
            if (items.isEmpty) return _buildEmptyState(isDark);
            return _buildInboxList(items);
          },
        ),
      ),
    );
  }

  Widget _buildInboxList(List<NotificationsInboxData> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return NotificationRow(
          item: item,
          onTap: () {
            context.push('/notifications/${item.id}');
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.bellOff,
                size: 48,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'notifications.empty_state'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError(Object error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Text(
              error.toString(),
              style: const TextStyle(color: AppColors.danger),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
