import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:na_app/core/storage/secure_token_store.dart';
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
  Timer? _typingTimer;
  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<TypingEvent>? _typingSub;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
    _messageSub = ref.read(chatRepositoryProvider).messages.listen(_onNewMessage);
    _typingSub = ref.read(chatRepositoryProvider).typingStream.listen((event) {
      if (event.userId == widget.counterpartyId) {
        setState(() => _counterpartyTyping = event.isTyping);
      }
    });
    ref.read(chatRepositoryProvider).listConversations();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await ref.read(secureTokenStoreProvider).accessToken;
    if (mounted) setState(() => _accessToken = token);
  }

  void _onNewMessage(ChatMessage message) {
    bool belongsToConversation;
    if (_conversationId.isNotEmpty) {
      belongsToConversation = message.conversationId == _conversationId;
    } else {
      belongsToConversation = message.senderId == widget.counterpartyId ||
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
    });

    _scrollToBottom();

    if (message.senderId == widget.counterpartyId && _conversationId.isNotEmpty) {
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
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendText(String text) {
    final chatController = ref.read(chatControllerProvider);
    chatController.sendTextMessage(recipientId: widget.counterpartyId, text: text);
    _scrollToBottom();
  }

  void _handleTypingChanged(String text) {
    final chatController = ref.read(chatControllerProvider);

    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      chatController.sendTyping(recipientId: widget.counterpartyId, isTyping: true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        chatController.sendTyping(recipientId: widget.counterpartyId, isTyping: false);
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _typingSub?.cancel();
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
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
        backgroundColor: isDark ? AppColors.darkBgSurface : AppColors.bgCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
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
                        message: message,
                        currentUserId: currentUserId,
                        baseUrl: const String.fromEnvironment(
                          'API_BASE_URL',
                          defaultValue: 'http://10.0.2.2:3000',
                        ),
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
            onTextChanged: _handleTypingChanged,
            enabled: true,
            hintText: 'Message ${widget.counterpartyName.split(' ').first}...',
          ),
        ],
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  final String counterpartyName;
  final String? subjectTitle;

  const _EmptyConversation({
    required this.counterpartyName,
    this.subjectTitle,
  });

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
                counterpartyName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join('').toUpperCase(),
                style: TextStyle(
                  color: isDark ? AppColors.darkAccentDeep : AppColors.accentDeep,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              counterpartyName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
              'Send a message to start the conversation.',
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