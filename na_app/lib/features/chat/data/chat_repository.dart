import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/core/api/api_exception.dart';
import 'package:na_app/core/api/dio_client.dart';
import 'package:na_app/core/api/endpoints.dart';
import 'package:na_app/core/realtime/chat_socket.dart';
import 'package:na_app/core/storage/secure_token_store.dart';
import 'package:na_app/features/chat/domain/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final instance = ChatRepository(
    dio: ref.watch(dioProvider),
    chatSocket: ref.watch(chatSocketProvider),
    tokenStore: ref.watch(secureTokenStoreProvider),
  );
  ref.onDispose(() => instance.dispose());
  return instance;
});

class ChatRepository {
  final Dio _dio;
  final ChatSocket _chatSocket;

  final _conversationsController = StreamController<List<Conversation>>.broadcast();
  final _messagesController = StreamController<ChatMessage>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();

  List<Conversation> _conversations = [];
  final List<ChatMessage> _messages = [];
  final List<PendingMessage> _pendingQueue = [];
  final int _maxImageBytes = 10 * 1024 * 1024;
  final Set<String> _allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
  };

  StreamSubscription<Map<String, dynamic>>? _newMessageSub;
  StreamSubscription<Map<String, dynamic>>? _statusUpdateSub;
  StreamSubscription<Map<String, dynamic>>? _conversationReadSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;
  StreamSubscription<List<Map<String, dynamic>>>? _pendingMessagesSub;

  Stream<List<Conversation>> get conversations => _conversationsController.stream;
  Stream<ChatMessage> get messages => _messagesController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  List<PendingMessage> get pendingMessages => List.unmodifiable(_pendingQueue);

  ChatRepository({
    required Dio dio,
    required ChatSocket chatSocket,
    required SecureTokenStore tokenStore,
  })  : _dio = dio,
        _chatSocket = chatSocket {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _newMessageSub = _chatSocket.newMessage.listen(_handleNewMessage);
    _statusUpdateSub = _chatSocket.statusUpdate.listen(_handleStatusUpdate);
    _conversationReadSub = _chatSocket.conversationRead.listen(_handleConversationRead);
    _typingSub = _chatSocket.typingIndicator.listen(_handleTypingIndicator);
    _pendingMessagesSub = _chatSocket.pendingMessages.listen(_handlePendingMessages);
  }

  Future<List<Conversation>> listConversations() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Endpoints.chat.conversations,
      );
      final data = response.data;
      if (data == null) return [];
      final rawList = data['conversations'] as List<dynamic>? ?? [];
      _conversations = rawList
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
      _conversationsController.add(_conversations);
      return _conversations;
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  Future<String?> uploadImage(File imageFile, String contentType) async {
    if (!_allowedMimeTypes.contains(contentType)) {
      throw ApiException(
        statusCode: 415,
        code: 'UNSUPPORTED_MEDIA_TYPE',
        message: 'Only JPEG, PNG, WebP, and HEIC images are allowed.',
      );
    }
    final fileSize = await imageFile.length();
    if (fileSize > _maxImageBytes) {
      throw ApiException(
        statusCode: 413,
        code: 'PAYLOAD_TOO_LARGE',
        message: 'Image must be smaller than 10 MB.',
      );
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
          contentType: DioMediaType.parse(contentType),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        Endpoints.media.chatUpload,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data?['id'] as String?;
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  void sendMessage({
    required String recipientId,
    String? text,
    String? imageFileId,
  }) {
    final messageType = imageFileId != null ? 'image' : 'text';
    final localId = 'pending-${DateTime.now().millisecondsSinceEpoch}';

    final pending = PendingMessage(
      localId: localId,
      recipientId: recipientId,
      text: text,
      imageFileId: imageFileId,
      type: messageType == 'image' ? MessageType.image : MessageType.text,
      status: MessageDeliveryStatus.pending,
      createdAt: DateTime.now(),
    );
    _pendingQueue.add(pending);

    final provisional = ChatMessage(
      id: localId,
      conversationId: '',
      senderId: '',
      recipientId: recipientId,
      type: messageType == 'image' ? MessageType.image : MessageType.text,
      text: text,
      imageFileId: imageFileId,
      sentAt: DateTime.now(),
      status: MessageDeliveryStatus.pending,
    );
    _messages.add(provisional);
    _messagesController.add(provisional);

    _chatSocket.sendMessage(
      recipientId: recipientId,
      text: text,
      imageFileId: imageFileId,
      messageType: messageType,
      clientMessageId: localId,
    );
  }

  void markRead({required String conversationId, required String senderId}) {
    _chatSocket.markRead(conversationId: conversationId, senderId: senderId);
  }

  void sendTyping({required String recipientId, required bool isTyping}) {
    _chatSocket.sendTyping(recipientId: recipientId, isTyping: isTyping);
  }

  void deliveryAck({required String messageId, required String senderId}) {
    _chatSocket.deliveryAck(messageId: messageId, senderId: senderId);
  }

  Future<void> connectSocket() async {
    await _chatSocket.connect();
  }

  void disconnectSocket() {
    _chatSocket.disconnect();
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final message = ChatMessage.fromJson(data);
      final clientMessageId = data['clientMessageId'] as String?;

      final existingIdx = clientMessageId != null
          ? _messages.indexWhere((m) => m.id == clientMessageId)
          : _messages.indexWhere((m) => m.id == message.id);

      if (existingIdx >= 0) {
        final merged = message.copyWith(
          id: message.id.isNotEmpty ? message.id : _messages[existingIdx].id,
          conversationId: message.conversationId.isNotEmpty
              ? message.conversationId
              : _messages[existingIdx].conversationId,
        );
        _messages[existingIdx] = merged;
        _messagesController.add(merged);
      } else {
        _messages.add(message);
        _messagesController.add(message);
      }

      deliveryAck(messageId: message.id, senderId: message.senderId);

      final pendingIdx = _pendingQueue.indexWhere((m) =>
          m.localId == clientMessageId && m.status == MessageDeliveryStatus.pending);
      if (pendingIdx >= 0) {
        _pendingQueue.removeAt(pendingIdx);
      }

      listConversations();
    } catch (_) {}
  }

  void _handleStatusUpdate(Map<String, dynamic> data) {
    final messageId = data['messageId'] as String?;
    final newStatus = data['status'] as String?;
    if (messageId == null || newStatus == null) {
      listConversations();
      return;
    }

    final parsedStatus = MessageDeliveryStatus.values.firstWhere(
      (e) => e.name == newStatus,
      orElse: () => MessageDeliveryStatus.sent,
    );

    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx >= 0) {
      _messages[idx] = _messages[idx].copyWith(status: parsedStatus);
      _messagesController.add(_messages[idx]);
    }

    listConversations();
  }

  void _handleConversationRead(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    if (conversationId != null) {
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].conversationId == conversationId) {
          _messages[i] = _messages[i].copyWith(status: MessageDeliveryStatus.read);
          _messagesController.add(_messages[i]);
        }
      }
    }
    listConversations();
  }

  void _handleTypingIndicator(Map<String, dynamic> data) {
    final userId = data['userId'] as String?;
    final isTyping = data['isTyping'] as bool? ?? false;
    if (userId != null) {
      _typingController.add(TypingEvent(userId: userId, isTyping: isTyping));
    }
  }

  void _handlePendingMessages(List<Map<String, dynamic>> data) {
    for (final msgData in data) {
      try {
        final message = ChatMessage.fromJson(msgData);
        final existingIdx = _messages.indexWhere((m) => m.id == message.id);
        if (existingIdx >= 0) {
          _messages[existingIdx] = message;
        } else {
          _messages.add(message);
        }
        _messagesController.add(message);
        deliveryAck(messageId: message.id, senderId: message.senderId);
      } catch (_) {}
    }
    listConversations();
  }

  void dispose() {
    _newMessageSub?.cancel();
    _statusUpdateSub?.cancel();
    _conversationReadSub?.cancel();
    _typingSub?.cancel();
    _pendingMessagesSub?.cancel();
    _conversationsController.close();
    _messagesController.close();
    _typingController.close();
  }

  ApiException _mapException(DioException e) {
    if (e.error is ApiException) return e.error as ApiException;
    return ApiException(
      statusCode: e.response?.statusCode ?? 0,
      code: 'UNKNOWN',
      message: e.message ?? '',
    );
  }
}

class TypingEvent {
  final String userId;
  final bool isTyping;
  const TypingEvent({required this.userId, required this.isTyping});
}