import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/utils/time_ago.dart';
import 'package:na_app/core/widgets/empty_state.dart';
import 'package:na_app/features/chat/data/chat_repository.dart';
import 'package:na_app/features/chat/domain/chat_models.dart';
import 'package:na_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:animate_do/animate_do.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversationsAsync = ref.watch(chatListProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBgCanvas : AppColors.bgCanvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المحادثات',
                            style: GoogleFonts.cairo(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تواصل مع مدرسيك وزملائك بسهولة.',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkAccent : AppColors.accent).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.messageSquareText,
                          color: isDark ? AppColors.darkAccent : AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: conversationsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                  error: (e, st) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.circleAlert, size: 48, color: AppColors.danger),
                        const SizedBox(height: 16),
                        Text(
                          'تعذر تحميل المحادثات',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(chatListProvider.notifier).refresh(),
                          child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                        ),
                      ],
                    ),
                  ),
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return FadeIn(
                        child: EmptyState(
                          icon: LucideIcons.messageCircle,
                          title: 'لا توجد محادثات بعد',
                          message: 'أدخل كود المادة لفتح محادثات المعلمين والمجموعات.',
                          actionLabel: 'إدخال كود مادة',
                          onAction: () => context.go('/subjects/enter-code'),
                        ),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: () => ref.read(chatListProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conv = conversations[index];
                          return FadeInUp(
                            delay: Duration(milliseconds: 100 + (index * 50)),
                            duration: const Duration(milliseconds: 500),
                            child: _ConversationRow(
                              conversation: conv,
                              onTap: () => _openConversation(conv),
                              isDark: isDark,
                            ),
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
        'subjectTitle': conv.subjectTitle,
      });
    }
  }
}

class _ConversationRow extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final bool isDark;

  const _ConversationRow({
    required this.conversation,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final initials = conversation.counterpartyName
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join('');

    final hasUnread = conversation.unreadCount > 0;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasUnread 
                ? accentColor.withValues(alpha: 0.3) 
                : (isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle),
              width: hasUnread ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              _Avatar(initials: initials, isDark: isDark, hasUnread: hasUnread),
              const SizedBox(width: 16),
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
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conversation.subjectTitle,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (conversation.lastMessage != null)
                      Text(
                        conversation.lastMessage!.text ?? (conversation.lastMessage!.hasImage ? '📷 صورة' : ''),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                          color: hasUnread
                              ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage != null
                          ? timeAgo(conversation.lastMessage!.sentAt)
                          : 'لا توجد رسائل بعد',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    '${conversation.unreadCount}',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initials;
  final bool isDark;
  final bool hasUnread;

  const _Avatar({required this.initials, required this.isDark, required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    final accentColor = isDark ? AppColors.darkAccent : AppColors.accent;
    
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.2),
            accentColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        shape: BoxShape.circle,
        border: hasUnread 
          ? Border.all(color: accentColor, width: 2)
          : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.cairo(
          color: accentColor,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}