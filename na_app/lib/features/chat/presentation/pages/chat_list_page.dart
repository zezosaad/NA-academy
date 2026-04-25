import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_shapes.dart';
import 'package:na_app/core/utils/time_ago.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/chat/data/chat_repository.dart';
import 'package:na_app/features/chat/domain/chat_models.dart';
import 'package:na_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';

final chatListProvider = AsyncNotifierProvider<ChatListNotifier, List<Conversation>>(
  ChatListNotifier.new,
);

class ChatListNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final repo = ref.watch(chatRepositoryProvider);
    final userId = ref.read(authControllerProvider.notifier).currentUser?.id ?? '';
    ref.read(chatControllerProvider).setCurrentUserId(userId);
    ref.onDispose(() {
      repo.disconnectSocket();
    });
    await repo.connectSocket();
    return repo.listConversations();
  }

  Future<void> refresh() async {
    final repo = ref.read(chatRepositoryProvider);
    final conversations = await repo.listConversations();
    state = AsyncValue.data(conversations);
  }
}

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatListProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final conversationsAsync = ref.watch(chatListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: theme.textTheme.displayLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your tutors and study groups.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: conversationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Text(
                    'Could not load conversations',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.messageCircle,
                      title: 'No conversations yet',
                      message: 'Enter a subject code to unlock tutors.',
                      actionLabel: 'Enter a code',
                      onAction: () => context.go('/subjects/enter-code'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.read(chatListProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        return _ConversationRow(
                          conversation: conv,
                          onTap: () => _openConversation(conv),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openConversation(Conversation conv) {
    if (conv.virtual) {
      context.go('/chat/virtual/${conv.counterpartyId}', extra: {
        'counterpartyName': conv.counterpartyName,
        'subjectId': conv.subjectId,
        'subjectTitle': conv.subjectTitle,
      });
    } else {
      context.go('/chat/${conv.id}', extra: {
        'counterpartyId': conv.counterpartyId,
        'counterpartyName': conv.counterpartyName,
        'subjectId': conv.subjectId,
      });
    }
  }
}

class _ConversationRow extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final initials = conversation.counterpartyName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join('');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppShapes.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccentSoft : AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  color: isDark ? AppColors.darkAccentDeep : AppColors.accentDeep,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.counterpartyName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: conversation.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        conversation.subjectTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: isDark ? AppColors.darkAccentDeep : AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (conversation.lastMessage != null) ...[
                    Text(
                      conversation.lastMessage!.text ?? (conversation.lastMessage!.hasImage ? '📷 Photo' : ''),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        color: conversation.unreadCount > 0
                            ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    conversation.lastMessage != null
                        ? timeAgo(conversation.lastMessage!.sentAt)
                        : 'No messages yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                width: 22,
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppShapes.pillRadius),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}