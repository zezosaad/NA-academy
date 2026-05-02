import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/theme/app_motion.dart';
import 'package:na_app/core/widgets/max_text_scale.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/storage/secure_token_store.dart';
import 'package:na_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:na_app/features/chat/data/chat_repository.dart';
import 'package:na_app/features/chat/domain/chat_models.dart';
import 'package:na_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:na_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:na_app/features/chat/presentation/widgets/composer.dart';
import 'package:na_app/features/chat/presentation/widgets/typing_indicator.dart';

class ChatThreadPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String counterpartyId;
  final String counterpartyName;
  final String? subjectTitle;
  final bool isVirtual;

  const ChatThreadPage({
    super.key,
    required this.conversationId,
    required this.counterpartyId,
    required this.counterpartyName,
    this.subjectTitle,
    this.isVirtual = false,
  });

  @override
  ConsumerState<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends ConsumerState<ChatThreadPage> {
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  late String _conversationId;
  bool _counterpartyTyping = false;
  bool _isTyping = false;
  bool _isUploadingImage = false;
  bool _isLoadingHistory = false;
  Timer? _typingTimer;
  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<TypingEvent>? _typingSub;
  StreamSubscription<String>? _errorSub;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    final currentUserId =
        ref.read(authControllerProvider.notifier).currentUser?.id ?? '';
    if (currentUserId.isNotEmpty) {
      ref.read(chatControllerProvider).setCurrentUserId(currentUserId);
    }
    unawaited(ref.read(chatRepositoryProvider).connectSocket());
    _messageSub = ref
        .read(chatRepositoryProvider)
        .messages
        .listen(_onNewMessage);
    _typingSub = ref.read(chatRepositoryProvider).typingStream.listen((event) {
      if (event.userId == widget.counterpartyId) {
        setState(() => _counterpartyTyping = event.isTyping);
      }
    });
    _errorSub = ref.read(chatRepositoryProvider).errors.listen((message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.danger),
        );
    });
    ref.read(chatRepositoryProvider).listConversations();
    _initTokenThenHistory();
  }

  Future<void> _initTokenThenHistory() async {
    final token = await ref.read(secureTokenStoreProvider).accessToken;
    if (!mounted) return;
    setState(() => _accessToken = token);
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_conversationId.isEmpty) return;
    setState(() => _isLoadingHistory = true);

    try {
      final history = await ref
          .read(chatRepositoryProvider)
          .getConversationMessages(_conversationId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history)
          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      });
      _markConversationReadIfNeeded();
      _scrollToBottom();
    } catch (_) {
      // Keep socket live updates working even if history request fails.
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  void _markConversationReadIfNeeded() {
    if (_conversationId.isEmpty) return;

    final hasUnreadFromCounterparty = _messages.any(
      (message) =>
          message.senderId == widget.counterpartyId &&
          message.status != MessageDeliveryStatus.read,
    );
    if (!hasUnreadFromCounterparty) return;

    ref
        .read(chatControllerProvider)
        .markConversationRead(
          conversationId: _conversationId,
          senderId: widget.counterpartyId,
        );
  }

  void _onNewMessage(ChatMessage message) {
    bool belongsToConversation;
    if (_conversationId.isNotEmpty) {
      belongsToConversation = message.conversationId == _conversationId;
    } else {
      belongsToConversation =
          message.senderId == widget.counterpartyId ||
          message.recipientId == widget.counterpartyId;
    }

    if (!belongsToConversation) return;

    if (_conversationId.isEmpty && message.conversationId.isNotEmpty) {
      setState(() => _conversationId = message.conversationId);
    }

    setState(() {
      final existingIdx = _messages.indexWhere((m) => m.id == message.id);
      if (existingIdx >= 0) {
        _messages[existingIdx] = message;
      } else {
        _messages.add(message);
      }
      _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    });

    _scrollToBottom();

    if (message.senderId == widget.counterpartyId &&
        _conversationId.isNotEmpty) {
      final chatController = ref.read(chatControllerProvider);
      chatController.markConversationRead(
        conversationId: _conversationId,
        senderId: widget.counterpartyId,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (AppMotion.shouldReduceMotion(context)) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _handleSendText(String text) {
    final chatController = ref.read(chatControllerProvider);
    chatController.sendTextMessage(
      recipientId: widget.counterpartyId,
      text: text,
    );
    _scrollToBottom();
  }

  String _inferImageMimeType(File file) {
    final lowerPath = file.path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    if (lowerPath.endsWith('.heic')) return 'image/heic';
    if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/jpeg';
  }

  Future<void> _handleSendImage(File imageFile) async {
    if (_isUploadingImage) return;

    setState(() => _isUploadingImage = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final chatController = ref.read(chatControllerProvider);
      final mimeType = _inferImageMimeType(imageFile);
      final imageFileId = await repo.uploadImage(imageFile, mimeType);

      if (imageFileId == null || imageFileId.isEmpty) {
        throw Exception('Failed to upload image');
      }

      chatController.sendImageMessage(
        recipientId: widget.counterpartyId,
        imageFileId: imageFileId,
      );
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _handleTypingChanged(String text) {
    final chatController = ref.read(chatControllerProvider);

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      chatController.sendTyping(
        recipientId: widget.counterpartyId,
        isTyping: true,
      );
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        chatController.sendTyping(
          recipientId: widget.counterpartyId,
          isTyping: false,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _errorSub?.cancel();
    _typingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chatController = ref.watch(chatControllerProvider);
    final currentUserId = chatController.currentUserId;

    return MaxTextScale(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              LucideIcons.chevronLeft,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'chat.thread.goBack'.tr(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.counterpartyName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.subjectTitle != null)
                Text(
                  widget.subjectTitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkAccentDeep : AppColors.accent,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          backgroundColor: isDark
              ? AppColors.darkBgSurface
              : AppColors.bgCanvas,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: _isLoadingHistory
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : _messages.isEmpty
                  ? _EmptyConversation(
                      counterpartyName: widget.counterpartyName,
                      subjectTitle: widget.subjectTitle,
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return const SizedBox(height: 16);
                        }
                        final message = _messages[index];
                        return MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          currentUserId: currentUserId,
                          baseUrl: ref.read(dioProvider).options.baseUrl,
                          accessToken: _accessToken,
                        );
                      },
                    ),
            ),
            ChatTypingIndicator(
              userName: widget.counterpartyName.split(' ').first,
              isTyping: _counterpartyTyping,
            ),
            Composer(
              onSendText: _handleSendText,
              onSendImage: _handleSendImage,
              onTextChanged: _handleTypingChanged,
              enabled: !_isUploadingImage,
              hintText: 'chat.thread.composerHintNamed'.tr(
                namedArgs: {'name': widget.counterpartyName.split(' ').first},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  final String counterpartyName;
  final String? subjectTitle;

  const _EmptyConversation({required this.counterpartyName, this.subjectTitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkAccentSoft : AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                counterpartyName
                    .split(' ')
                    .map((w) => w.isNotEmpty ? w[0] : '')
                    .take(2)
                    .join('')
                    .toUpperCase(),
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkAccentDeep
                      : AppColors.accentDeep,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              counterpartyName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subjectTitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subjectTitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkAccentDeep : AppColors.accent,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'chat.thread.startConversationPrompt'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
