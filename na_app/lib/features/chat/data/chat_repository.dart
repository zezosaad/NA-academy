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
  return ChatRepository(
    dio: ref.watch(dioProvider),
    chatSocket: ref.watch(chatSocketProvider),
    tokenStore: ref.watch(secureTokenStoreProvider),
  );
});

class ChatRepository {
  final Dio _dio;
  final ChatSocket _chatSocket;

  final _conversationsController = StreamController<List<Conversation>>.broadcast();
  final _messagesController = StreamController<ChatMessage>.broadcast();

  List<Conversation> _conversations = [];
  final List<PendingMessage> _pendingQueue = [];
  final int _maxImageBytes = 10 * 1024 * 1024;
  final Set<String> _allowedMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
  };

  Stream<List<Conversation>> get conversations => _conversationsController.stream;
  Stream<ChatMessage> get messages => _messagesController.stream;
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
    _chatSocket.newMessage.listen(_handleNewMessage);
    _chatSocket.statusUpdate.listen(_handleStatusUpdate);
    _chatSocket.conversationRead.listen(_handleConversationRead);
    _chatSocket.typingIndicator.listen(_handleTypingIndicator);
    _chatSocket.pendingMessages.listen(_handlePendingMessages);
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

    _chatSocket.sendMessage(
      recipientId: recipientId,
      text: text,
      imageFileId: imageFileId,
      messageType: messageType,
    );

    final idx = _pendingQueue.indexWhere((m) => m.localId == localId);
    if (idx >= 0) _pendingQueue.removeAt(idx);
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
      _messagesController.add(message);
      deliveryAck(messageId: message.id, senderId: message.senderId);
      listConversations();
    } catch (_) {}
  }

  void _handleStatusUpdate(Map<String, dynamic> data) {
    listConversations();
  }

  void _handleConversationRead(Map<String, dynamic> data) {
    listConversations();
  }

  void _handleTypingIndicator(Map<String, dynamic> data) {}

  void _handlePendingMessages(List<Map<String, dynamic>> data) {
    for (final msgData in data) {
      try {
        final message = ChatMessage.fromJson(msgData);
        _messagesController.add(message);
        deliveryAck(messageId: message.id, senderId: message.senderId);
      } catch (_) {}
    }
    listConversations();
  }

  void dispose() {
    _conversationsController.close();
    _messagesController.close();
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