import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:na_app/core/storage/secure_token_store.dart';

final chatSocketProvider = Provider<ChatSocket>((ref) {
  return ChatSocket(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000',
    ),
    tokenStore: ref.watch(secureTokenStoreProvider),
  );
});

class ChatSocket {
  final String _baseUrl;
  final SecureTokenStore _tokenStore;
  io.Socket? _socket;

  final _newMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingIndicatorController = StreamController<Map<String, dynamic>>.broadcast();
  final _pendingMessagesController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<Map<String, dynamic>> get newMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get statusUpdate => _statusUpdateController.stream;
  Stream<Map<String, dynamic>> get conversationRead => _conversationReadController.stream;
  Stream<Map<String, dynamic>> get typingIndicator => _typingIndicatorController.stream;
  Stream<List<Map<String, dynamic>>> get pendingMessages => _pendingMessagesController.stream;

  bool get isConnected => _socket?.connected ?? false;

  ChatSocket({
    required String baseUrl,
    required SecureTokenStore tokenStore,
  })  : _baseUrl = baseUrl,
        _tokenStore = tokenStore;

  Future<void> connect() async {
    final token = await _tokenStore.accessToken;
    if (token == null || token.isEmpty) return;

    _socket?.dispose();
    _socket = io.io('$_baseUrl/chat', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.on('new_message', (data) {
      _newMessageController.add(data as Map<String, dynamic>);
    });

    _socket!.on('status_update', (data) {
      _statusUpdateController.add(data as Map<String, dynamic>);
    });

    _socket!.on('conversation_read', (data) {
      _conversationReadController.add(data as Map<String, dynamic>);
    });

    _socket!.on('typing_indicator', (data) {
      _typingIndicatorController.add(data as Map<String, dynamic>);
    });

    _socket!.on('pending_messages', (data) {
      final messages = (data as List).cast<Map<String, dynamic>>();
      _pendingMessagesController.add(messages);
    });

    _socket!.on('connect_error', (_) async {
      await _reconnectWithRefresh();
    });

    _socket!.connect();
  }

  void sendMessage({
    required String recipientId,
    String? text,
    String? imageFileId,
    String messageType = 'text',
  }) {
    _socket?.emit('send_message', {
      'recipientId': recipientId,
      if (text != null) 'text': text,
      if (imageFileId != null) 'imageFileId': imageFileId,
      'messageType': messageType,
    });
  }

  void markRead({required String conversationId, required String senderId}) {
    _socket?.emit('mark_read', {
      'conversationId': conversationId,
      'senderId': senderId,
    });
  }

  void sendTyping({required String recipientId, required bool isTyping}) {
    _socket?.emit('typing', {
      'recipientId': recipientId,
      'isTyping': isTyping,
    });
  }

  void deliveryAck({required String messageId, required String senderId}) {
    _socket?.emit('delivery_ack', {
      'messageId': messageId,
      'senderId': senderId,
    });
  }

  Future<void> _reconnectWithRefresh() async {
    final refreshToken = await _tokenStore.refreshToken;
    if (refreshToken == null) {
      disconnect();
      return;
    }
    await connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _newMessageController.close();
    _statusUpdateController.close();
    _conversationReadController.close();
    _typingIndicatorController.close();
    _pendingMessagesController.close();
  }
}
